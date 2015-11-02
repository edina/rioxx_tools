# RIOXX Tools
The code in this repository is intended to support the implementation of the [RIOXX Metadata Application Profile](http://rioxx.net). Both the metadata profile and this software are developed and maintained by [EDINA](http://www.edina.ac.uk)

This code consists of a set of libraries written in Ruby, and a simple command line tool ('compliance_check_console.rb') which:

* discovers those repositories which declare support for RIOXX
* harvests sample records from those repositories
* validates each record against a set of encoded rules
* writes a report (in JSON format) which is designed to be processed by [Hugo](https://gohugo.io), a static web-site generator

**This code is used to generate the report on the [RIOXX implementations page](http://rioxx.net/implementation/)**

## Caveats
this software is:

* not designed to scale - it is built to operate on small samples
* mainly intended to provide a measure of automated testing, to offer feedback to implementers
* not particularly robust in network operations - no retries for example
* not being actively developed - it is provided primarily for 

## Dependencies

### Libraries
This software has a number of dependencies on 3rd-party Ruby libraries or gems (see the Gemfile).

### External services
* [OpenDOAR API](http://opendoar.org/api13.php?co=gb&show=max&sort=rname)

## How to use
1. clone this repository to a local folder
2. rename, or make a copy of 'config_SAMPLE.yaml' to 'config.yaml'
3. edit 'config.yaml' to whatever values you want to use. In practice, this should only require setting 'data_dir_path' and 'web_report_data_dir_path'. These two folders must exist before running the software.
4. make 'compliance_check_console.rb' executable
5. run 'compliance_check_console.rb'