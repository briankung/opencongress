require 'remote_forgery_protection/remote_forgery_protection'

ActionView::Base.send :include, RemoteForgeryProtection::ViewHelpers