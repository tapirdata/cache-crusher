import { ExtractorCatalog } from "../extractor-catalog"
import { ExtractorOptions } from "../options"

class Extractor {

  public static handle: string = "base"
  public static exts: string[] = []

  protected urlBase: string
  protected partBrick: string
  protected pathBrick: string
  private pattern: RegExp

  constructor(options: ExtractorOptions) {
    this.urlBase = options.urlBase || ""
    if (options.partBrick) {
      this.partBrick = options.partBrick
    }
    this.pathBrick = `${this.urlBase}(?:${this.partBrick}/)*${this.partBrick}`
  }

  public getBrick() {
    const brickParts = [
      "(", (this as any).preBrick, ")",
      "(", (this as any).openBrick, ")",
      "(", (this as any).pathBrick, ")",
      "(", (this as any).queryBrick, ")",
      "(", (this as any).closeBrick, ")",
      "(", (this as any).postBrick, ")",
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

Object.assign(Extractor.prototype, {
  preambleBrickNum: 2,
  pathBrickNum: 1,
  queryBrickNum: 1,

  partBrick: '[^\/#?\'"]+',
  preBrick: "",
  postBrick: "",
  openBrick: '[\'"]',
  closeBrick: "\\2",
  queryBrick: '(?:\\?[^#"\']*)?',
})

export default Extractor
export { ExtractorOptions }
