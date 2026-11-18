# frozen_string_literal: true

RSpec.describe ReviewsController do
  fab!(:admin)
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:reviews_category) { Fabricate(:category, name: "Reviews") }

  before do
    SiteSetting.review_form_enabled = true
    SiteSetting.review_form_category = reviews_category.id
  end

  let(:review_params) do
    { review: { name: "Alice", email: "alice@example.com", review_text: "Great product!" } }
  end

  describe "POST /reviews" do
    it "posts the review to the review category and stores it" do
      post "/reviews.json", params: review_params

      expect(response.status).to eq(200)
      body = response.parsed_body["review"]
      expect(body["name"]).to eq("Alice")
      expect(body).not_to have_key("email")

      topic = Topic.where(category: reviews_category).last
      expect(topic.title).to eq("Review from Alice")
      expect(topic.first_post.raw).to eq("Great product!")
      expect(topic.user).to eq(Discourse.system_user)

      stored = ReviewStore.get_reviews[body["id"]]
      expect(stored["email"]).to eq("alice@example.com")
      expect(stored["topic_id"]).to eq(topic.id)
    end

    it "does not include the submitter's email in the post" do
      post "/reviews.json", params: review_params
      expect(Post.last.raw).not_to include("alice@example.com")
    end

    it "uses a placeholder when no name is given" do
      post "/reviews.json", params: { review: review_params[:review].merge(name: "") }
      expect(response.status).to eq(200)
      expect(Topic.last.title).to eq("Review from Anonymous reviewer")
    end

    it "returns 400 when email is missing or invalid" do
      post "/reviews.json", params: { review: { name: "Bob", review_text: "hi" } }
      expect(response.status).to eq(400)

      post "/reviews.json", params: { review: { email: "nope", review_text: "hi" } }
      expect(response.status).to eq(400)
      expect(ReviewStore.get_reviews).to be_empty
    end

    it "returns 400 when the review text is blank" do
      post "/reviews.json", params: { review: { email: "a@example.com", review_text: "  " } }
      expect(response.status).to eq(400)
    end

    it "returns 404 when no review category is configured" do
      SiteSetting.review_form_category = ""
      post "/reviews.json", params: review_params
      expect(response.status).to eq(404)
      expect(ReviewStore.get_reviews).to be_empty
    end

    it "returns 404 when the plugin is disabled" do
      SiteSetting.review_form_enabled = false
      post "/reviews.json", params: review_params
      expect(response.status).to eq(404)
    end

    it "does not let the submitter inject content via newlines in the name" do
      post "/reviews.json",
           params: {
             review: review_params[:review].merge(name: "Eve\nCc: victim@example.com"),
           }
      expect(Topic.last.title).not_to include("\n")
    end

    it "does not let an anonymous submitter post as an existing user" do
      post "/reviews.json",
           params: {
             review: {
               name: "Spoof",
               email: user.email,
               review_text: "posted as someone else",
             },
           }
      expect(response.status).to eq(200)
      expect(Post.where(user_id: user.id)).not_to exist
    end

    it "rate limits submissions" do
      RateLimiter.enable
      6.times { post "/reviews.json", params: review_params }
      expect(response.status).to eq(429)
    end
  end

  describe "GET /reviews" do
    it "is forbidden for anonymous users" do
      get "/reviews.json"
      expect(response.status).to eq(403)
    end

    it "is forbidden for regular users" do
      sign_in(user)
      get "/reviews.json"
      expect(response.status).to eq(403)
    end

    it "lists reviews for admins" do
      ReviewStore.add_review("abc", { "id" => "abc", "name" => "A" })
      sign_in(admin)
      get "/reviews.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["reviews"].map { |r| r["id"] }).to eq(["abc"])
    end
  end

  describe "DELETE /reviews/:review_id" do
    before { ReviewStore.add_review("abc", { "id" => "abc" }) }

    it "is forbidden for regular users" do
      sign_in(user)
      delete "/reviews/abc.json"
      expect(response.status).to eq(403)
      expect(ReviewStore.get_reviews).to have_key("abc")
    end

    it "removes the review for admins" do
      sign_in(admin)
      delete "/reviews/abc.json"
      expect(response.status).to eq(200)
      expect(ReviewStore.get_reviews).not_to have_key("abc")
    end
  end

  describe "core review queue" do
    it "is not overridden by the plugin" do
      sign_in(admin)
      get "/review.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body).to have_key("reviewables")
    end
  end
end
