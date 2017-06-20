export class TimeoutError extends Error {

  public tag: string
  public originTag: string
  public timeout?: number
  public message: string

  constructor(tag: string, originTag: string, timeout?: number) {
    super()
    this.tag = tag
    this.originTag = originTag
    this.timeout = timeout
    let originText
    if (this.originTag) {
      originText = `(by ${this.originTag}) `
    }
    this.message = `Timeout for tag '${this.tag} ${originText}after ${this.timeout}ms`
  }
}
