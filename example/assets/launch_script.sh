#!/bin/bash
gdbus call --session --dest dev.markvideon.DesktopEntryExample \
--object-path /dev/markvideon/DesktopEntryExample/Object \
--method org.freedesktop.Application.Open "['$1']" {}