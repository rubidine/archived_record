# Copyright (c) 2009 Todd Willey <todd@rubidine.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module ArchivedRecord
  def self.included kls
    kls.send :extend, ClassMethods
  end

  module ClassMethods
    def archived_record
      include InstanceMethods
      add_named_scopes
      set_default_scope
    end

    private
    def add_named_scopes
      named_scope :archived, {:conditions => 'archived_at IS NOT NULL'}
      named_scope :current, {:conditions => 'archived_at IS NULL'}
    end

    def set_default_scope
      default_scope :find => {:conditions => 'archived_at IS NULL'}
    end
  end

  module InstanceMethods
    def archived? time=Time.now
      archived_at and archived_at < time
    end

    def current? time=Time.now
      archived_at.nil? or archived_at > time
    end

    def archive! time=Time.now
      return if archived?
      update_attribute(:archived_at, time)
    end
  end
end
