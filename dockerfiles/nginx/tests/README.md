The routing logic for the nginx proxy is a bit fiddly.

This directory contains some tests for the routing logic, to save us from manual testing or just hoping it works!

The tests work by spinning up a pair of tiny test containers that have the same names as the containers in ECS, and making request to see if nginx is proxying correctly.

To run tests:

```console
$ py.test run_tests.py
```
