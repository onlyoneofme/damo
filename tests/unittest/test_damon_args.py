#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0

import argparse
import os
import sys
import unittest

bindir = os.path.dirname(os.path.realpath(__file__))
damo_dir = os.path.join(bindir, '..', '..')
sys.path.append(damo_dir)

import _damon
import _damon_args

class TestDamonArgs(unittest.TestCase):
    def test_damon_ctx_from_damon_args(self):
        parser = argparse.ArgumentParser()
        _damon_args.set_implicit_target_monitoring_argparser(parser)

        args = parser.parse_args(
                ('--sample 5000 --aggr 100000 --updr 1000000 ' +
                    '--minr 10 --maxr 1000 --regions=123-456 paddr').split())
        _damon_args.set_implicit_target_args_explicit(args)
        self.assertEqual(_damon_args.damon_ctx_from_damon_args(args),
            _damon.DamonCtx('0',
                _damon.DamonIntervals(5000, 100000, 1000000),
                _damon.DamonNrRegionsRange(10, 1000), 'paddr',
                [_damon.DamonTarget('0', None,
                    [_damon.DamonRegion(123, 456)])],
                []))

        args = parser.parse_args(
                ('--sample 5ms --aggr 100ms --updr 1s ' +
                    '--minr 10 --maxr 1,000 --regions=1K-4K paddr').split())
        _damon_args.set_implicit_target_args_explicit(args)
        self.assertEqual(_damon_args.damon_ctx_from_damon_args(args),
            _damon.DamonCtx('0',
                _damon.DamonIntervals(5000, 100000, 1000000),
                _damon.DamonNrRegionsRange(10, 1000), 'paddr',
                [_damon.DamonTarget('0', None,
                    [_damon.DamonRegion(1024, 4096)])],
                []))

        parser = argparse.ArgumentParser()
        _damon_args.set_explicit_target_argparser(parser)

        args = parser.parse_args(
                ('--sample 5ms --aggr 100ms --updr 1s ' +
                    '--minr 10 --maxr 1,000 --regions=1K-4K ' +
                    '--ops paddr').split())
        self.assertEqual(_damon_args.damon_ctx_from_damon_args(args),
            _damon.DamonCtx('0',
                _damon.DamonIntervals(5000, 100000, 1000000),
                _damon.DamonNrRegionsRange(10, 1000), 'paddr',
                [_damon.DamonTarget('0', None,
                    [_damon.DamonRegion(1024, 4096)])],
                [_damon.default_Damos]))

if __name__ == '__main__':
    unittest.main()