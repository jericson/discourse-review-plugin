import RestModel from "discourse/models/rest";

export default RestModel.extend({
  updateProperties() {
    return this.getProperties("name", "email", "review_text");
  },
});
