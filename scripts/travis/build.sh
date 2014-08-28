#!/bin/bash

set -e -o pipefail
. "$(dirname $0)/../env.sh"

echo '==========='
echo '== BUILD =='
echo '==========='

SIZE_TOO_BIG_COUNT=0

export SAUCE_ACCESS_KEY=`echo $SAUCE_ACCESS_KEY | rev`

function checkSize() {
  file=$1
  if [[ ! -e $file ]]; then
    echo Could not find file: $file
    SIZE_TOO_BIG_COUNT=$((SIZE_TOO_BIG_COUNT + 1));
  else
    expected=$2
    actual=`cat $file | gzip | wc -c`
    if (( 100 * $actual >= 105 * $expected )); then
      echo ${file} is too large expecting ${expected} was ${actual}.
      SIZE_TOO_BIG_COUNT=$((SIZE_TOO_BIG_COUNT + 1));
    fi
  fi
}


# E2E tests only?
if [[ $JOB == e2e-* ]]; then
  echo '---------------------------'
  echo '-- E2E TEST: AngularDart --'
  echo '---------------------------'
  $NGDART_BASE_DIR/scripts/run-e2e-test.sh
  exit 0
fi


if [[ $TESTS == "dart2js" ]]; then
  # skip auxiliary tests if we are only running dart2js
  echo '------------------------'
  echo '-- BUILDING: examples --'
  echo '------------------------'

  if [[ $CHANNEL == "DEV" ]]; then
    $DART "$NGDART_BASE_DIR/bin/pub_build.dart" -p example \
        -e "$NGDART_BASE_DIR/example/expected_warnings.json"
  else
    ( cd example; pub build )
  fi

  (
    echo '-----------------------------------'
    echo '-- BUILDING: verify dart2js size --'
    echo '-----------------------------------'
    cd $NGDART_BASE_DIR/example
    checkSize build/web/animation.dart.js 208021
    checkSize build/web/bouncing_balls.dart.js 213243
    checkSize build/web/hello_world.dart.js 210000
    checkSize build/web/todo.dart.js 214816
    if ((SIZE_TOO_BIG_COUNT > 0)); then
      exit 1
    else
      echo Generated JavaScript file size check OK.
    fi
  )
else
  echo '--------------'
  echo '-- TEST: io --'
  echo '--------------'
  $DART --checked $NGDART_BASE_DIR/test/io/all.dart

  echo '----------------------------'
  echo '-- TEST: symbol extractor --'
  echo '----------------------------'
  $DART --checked $NGDART_BASE_DIR/test/tools/symbol_inspector/symbol_inspector_spec.dart

  $NGDART_SCRIPT_DIR/generate-expressions.sh
  $NGDART_SCRIPT_DIR/analyze.sh

  echo '-----------------------'
  echo '-- TEST: transformer --'
  echo '-----------------------'
  $DART --checked $NGDART_BASE_DIR/test/tools/transformer/all.dart

  echo '---------------------'
  echo '-- TEST: changelog --'
  echo '---------------------'
  $NGDART_BASE_DIR/node_modules/jasmine-node/bin/jasmine-node \
        $NGDART_SCRIPT_DIR/changelog/;

  (
    echo '---------------------'
    echo '-- TEST: benchmark --'
    echo '---------------------'
    cd $NGDART_BASE_DIR/benchmark
    $PUB install

    for file in *_perf.dart; do
      echo ======= $file ========
      $DART $file
    done
  )
fi

echo '-----------------------'
echo '-- TEST: AngularDart --'
echo '-----------------------'
echo BROWSER=$BROWSERS
$NGDART_BASE_DIR/node_modules/jasmine-node/bin/jasmine-node playback_middleware/spec/ &&
node "node_modules/karma/bin/karma" start karma.conf \
    --reporters=junit,dots --port=8765 --runner-port=8766 \
    --browsers=$BROWSERS --single-run --no-colors 2>&1 | tee karma-output.log

if grep -q "WARN: iit" karma-output.log; then
  echo "ERROR: iit caused some tests to be excluded"
  exit 1
fi

if grep -q "WARN: ddescribe" karma-output.log; then
  echo "ERROR: ddescribe caused some tests to be excluded"
  exit 1
fi



echo '-------------------------' 
echo '-- DOCS: Generate Docs --'
echo '-------------------------'
if [[ ${TRAVIS_JOB_NUMBER:(-2)} == ".1" ]]; then
  echo $NGDART_SCRIPT_DIR/generate-documentation.sh;
  $NGDART_SCRIPT_DIR/generate-documentation.sh;
fi
