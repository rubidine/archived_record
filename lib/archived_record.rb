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
      extend InteriorClassMethods
      add_named_scopes
      set_default_scope
    end

    private
    def add_named_scopes
      named_scope :archived, {:conditions => 'archived_at IS NOT NULL'}
      named_scope :current, {:conditions => 'archived_at IS NULL'}
    end

    def set_default_scope
      default_scope :conditions => {:archived_at => nil}
    end
  end

  module InteriorClassMethods
    def after_archive *args, &blk
      options = args.extract_options!
      options.symbolize_keys!
      ar_callback = options[:callback] || :after_save
      append_after_archive_callback(ar_callback, args.first || blk)
      hook_after_archive_into_callback(ar_callback)
    end

    private
    def append_after_archive_callback ar_cb, callback
      cbc = read_inheritable_attribute(:after_archive_callbacks)
      cbc ||= {}
      cbc[ar_cb] ||= []
      cbc[ar_cb] << callback
      write_inheritable_attribute(:after_archvie_callbacks, cbc)
    end

    def hook_after_archive_into_callback ar_cb
      cbc = instance_variable_get("@#{ar_cb}_callbacks")
      return if cbc and cbc.detect{|x| x.identifier == 'after_archive'}
      send ar_cb, :identifier => 'after_archive' do |inst|
        inst.send :run_after_archvie_callbacks, ar_cb
      end
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

    private
    def run_after_archive_callbacks ar_cb
      return unless changes['archived_at'] and archived_at?
      chain = self.class.read_inheritable_attribute(:after_archive)
      return true unless chain and chain[ar_cb]
      chain[ar_cb].inject(true){|m,x| m && eval_after_archive_callback(x)}
    end

    def eval_after_archive_callback cb
      cb.is_a?(Symbol) ? send(cb) : instance_eval(&cb)
    end
  end
end
