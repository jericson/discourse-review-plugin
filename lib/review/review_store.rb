# coding: utf-8
# frozen_string_literal: true
class ReviewStore
  class << self
    def get_reviews
      PluginStore.get("review", "reviews") || {}
    end

    def add_review(review_id, review)
      reviews = get_reviews()
      reviews[review_id] = review
      PluginStore.set("review", "reviews", reviews)

      review
    end

    def remove_review(review_id)
      reviews = get_reviews()
      reviews.delete(review_id)
      PluginStore.set("review", "reviews", reviews)
    end
  end
end
