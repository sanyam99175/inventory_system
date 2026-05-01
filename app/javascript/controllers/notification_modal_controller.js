import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  open() {
    if (!this.hasContainerTarget) return
    this.containerTarget.classList.remove("hidden")
  }

  close() {
    if (!this.hasContainerTarget) return
    this.containerTarget.classList.add("hidden")
  }
}