#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Library for website operation"""

import os
import requests
from lxml import html
import http.cookiejar

import splinter

from lib_misc import TEMPDIR

USER_AGENT_FIREFOX_WIN10 = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:64.0) Gecko/20100101 Firefox/64.0'

_headers = {
    'user-agent': USER_AGENT_FIREFOX_WIN10,
}


def html_etree(url, **kwargs) -> html.HtmlElement:
    r = requests.get(url, headers=_headers, **kwargs)
    if r.ok:
        return html.document_fromstring(r.text)
    else:
        raise ConnectionError(r.status_code, r.reason)


def cookies_from_file(file_path: str) -> dict:
    cj = http.cookiejar.MozillaCookieJar(file_path)
    cj.load()
    return requests.utils.dict_from_cookiejar(cj)


class DownloadFailure(Exception):
    pass


def new_phantomjs(proxy=None, no_img=True) -> splinter.Browser:
    service_args_l = ['--webdriver-loglevel=WARN']
    if proxy:
        service_args_l.append('--proxy={}'.format(proxy))
    if no_img:
        service_args_l.append('--load-images=no')
    b = splinter.Browser(
        'phantomjs',
        user_agent=USER_AGENT_FIREFOX_WIN10,
        service_args=service_args_l,
        service_log_path=os.path.join(TEMPDIR, 'ghostdriver.log'),
    )
    b.driver.set_window_size(800, 600)
    return b


new_headless_browser = new_phantomjs


def try_dl_file(url: str, max_retries: int = 3) -> tuple:
    pass
