#!/bin/bash

# Step 1: Run Flutter tests and output them at directory `./coverage`:
flutter test --coverage

# Step 2: Generate LCOV report:
genhtml coverage/lcov.info -o coverage/report

# Step 3: Open the HTML coverage report:
#open ./coverage/report/index.html