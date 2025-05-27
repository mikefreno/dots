#!/bin/bash

update_count=$(brew outdated | wc -l)
echo $update_count
