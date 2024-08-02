# coding: utf-8
# frozen_string_literal: true

# name: discourse-review-plugin
# about: Allow anyone to post a review
# meta_topic_id: TODO
# version: 0.0.1
# authors: Jon Ericson
# url: https://github.com/jericson/discourse-review-plugin
# required_version: 2.7.0

enabled_site_setting :review_form_enabled

register_asset "stylesheets/review.scss"

module ::Review
  PLUGIN_NAME = "discourse-review-plugin"
end

require_relative "lib/review/engine"
require_relative File.expand_path("../lib/review/review_store.rb", __FILE__)

after_initialize do
  require_relative File.expand_path("../app/controllers/review_controller.rb", __FILE__)
  require_relative File.expand_path("../app/controllers/reviews_controller.rb", __FILE__)

  Discourse::Application.routes.append do
    # Map the path `/review` to `ReviewController`’s `index` method
    get "/review" => "review#index"

    get "/reviews" => "reviews#index"
    put "/reviews/:review_id" => "reviews#create"
    delete "/reviews/:review_id" => "reviews#destroy"
  end
end
