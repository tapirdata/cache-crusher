import { ExtractorOptions } from "./options"

export class Extractor {

  public static handle: string = "base"
  public static exts: string[] = []

  protected urlBase: string
  protected partBrick: string
  protected pathBrick: string
  private pattern?: RegExp

  constructor(options: ExtractorOptions) {
    this.urlBase = options.urlBase || ""
    if (options.partBrick) {
      this.partBrick = options.partBrick
    } else {
      this.partBrick = this.defaultPartBrick
    }
    this.pathBrick = `${this.urlBase}(?:${this.partBrick}/)*${this.partBrick}`
  }

  public get preambleBrickNum() { return 2 }
  public get pathBrickNum() { return 1 }
  public get queryBrickNum() { return 1 }

  public get defaultPartBrick() { return '[^\/#?\'"]+' }
  public get preBrick() { return "" }
  public get postBrick() { return "" }
  public get openBrick() { return '[\'"]' }
  public get closeBrick() { return "\\2" }
  public get queryBrick() { return '(?:\\?[^#"\']*)?' }

  public getBrick() {
    const brickParts = [
      "(", this.preBrick, ")",
      "(", this.openBrick, ")",
      "(", this.pathBrick, ")",
      "(", this.queryBrick, ")",
      "(", this.closeBrick, ")",
      "(", this.postBrick, ")",
    ]
    return brickParts.join("")
  }

  public createPattern(): RegExp {
    return new RegExp(this.getBrick())
  }

  public getPattern() {
    let pattern = this.pattern
    if (pattern == null) {
      pattern = this.createPattern()
      this.pattern = pattern
    }
    return pattern
  }

  public split(match: any) {
    const preambleCut = 1 + (this as any).preambleBrickNum
    const pathCut = preambleCut + (this as any).pathBrickNum
    const queryCut = pathCut + (this as any).queryBrickNum
    return {
      preamble: match.slice(1, preambleCut).join(""),
      path: match.slice(preambleCut, pathCut).join(""),
      query: match.slice(pathCut, queryCut).join(""),
      postamble: match.slice(queryCut).join(""),
    }
  }

}
