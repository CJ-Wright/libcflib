"""Database for accessing graph information"""
import os
import time

import zict

from libcflib.model import Artifact


class DB:
    """A database interface to the graph information """

    __inst = None

    def __new__(cls):
        # make the db a singleton
        if DB.__inst is None:
            DB.__inst = object.__new__(cls)
        return DB.__inst

    def __init__(self, cache_size=1000000):
        """

        Parameters
        ----------
        cache_size : int
            Size of the cache

        Caching forked from Streamz
        Copyright (c) 2017, Continuum Analytics, Inc. and contributors
        All rights reserved.

        """
        if os.path.exists($LIBCFGRAPH_DIR):
            git pull $LIBCFGRAPH_URL master
        else:
            git clone $LIBCFGRAPH_URL $LIBCFGRAPH_DIR --depth 1
        self.cache = {}
        self.lru = zict.LRU(cache_size, self.cache)
        self.times = {}

    def _build_whoosh(self):
        self.idx = 'whoosh'

    def search(self, **kwargs):
        """Search the database

        Parameters
        ----------
        kwargs : dict
            The keys to search on

        Yields
        -------
        res :
            The loaded artifact search results

        Caching forked from Streamz
        Copyright (c) 2017, Continuum Analytics, Inc. and contributors
        All rights reserved.
        """
        with self.idx.searcher() as searcher:
            results = searcher.search(**kwargs)
            for result in results:
                if result not in self.cache:
                    data = self.get_data(result)
                    self.cache[result] = data
                    # Cache the time so we can timeout the record
                    self.times[result] = time.time()
                else:
                    data = self.cache[results]
                yield data

    def get_data(self, data):
        """Get the artifact data from the database

        Parameters
        ----------
        data : tuple
            data for loading the artifact

        Returns
        -------

        """
        a = Artifact(*data)
        a._load()
        return a
