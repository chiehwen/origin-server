#--
# Copyright 2010 Red Hat, Inc.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

require 'rubygems'

require 'fileutils'
require 'getoptlong'
require 'json'
require "openshift-origin-common/models/model"
require "openshift-origin-common/models/user_model"
require "openshift-origin-common/exceptions/oo_exception"
require "openshift-origin-common/models/scaling"
require "openshift-origin-common/models/component_ref"
require "openshift-origin-common/models/group"
require "openshift-origin-common/models/connector"
require "openshift-origin-common/models/component"
require "openshift-origin-common/models/connection"
require "openshift-origin-common/models/profile"
require "openshift-origin-common/models/cartridge"