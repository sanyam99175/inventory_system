import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  open() {
    this.containerTarget.classList.remove("hidden")
    this.containerTarget.classList.add("flex")
  }

  close() {
    this.containerTarget.classList.add("hidden")
    this.containerTarget.classList.remove("flex")
  }
}