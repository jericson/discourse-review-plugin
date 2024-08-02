import Component from "@ember/component";

export default Component.extend({
  init() {
    this._super();
    this.set("review", []);
    this.fetchReviews();
    this.set("sent", "");
  },

  fetchReviews() {
    this.store.findAll("review").then((result) => {
      for (const review of result.content) {
        this.reviews.pushObject(review);
      }
    });
  },

  actions: {
    createReview(name, email, review_text) {
      const reviewRecord = this.store.createRecord("review", {
        id: Date.now(),
        name,
        email,
        review_text,
      });

      reviewRecord.save().then((result) => {
        this.reviews.pushObject(result.target);
      });

      this.set("sent", "true");
    },
  },
});
