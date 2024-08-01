# coding: utf-8
# frozen_string_literal: true

class ReviewController < ::ApplicationController
  requires_plugin "discourse-review-plugin"

  def index
    Rails.logger.info "🚂 Called the `ReviewController#index` method."
    render("Review")
  end
end
