import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.targetValue = this.element.dataset.modalTargetValue
  }

  open(event) {
    event.preventDefault()
    const modal = document.querySelector(this.targetValue)
    if (modal) {
      modal.classList.remove("hidden")
    }
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    this.element.classList.add("hidden")
  }
}
