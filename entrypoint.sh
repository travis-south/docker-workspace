#!/usr/bin/env bash

exec /sbin/setuser daker "$@" | tr -d '\r\n'