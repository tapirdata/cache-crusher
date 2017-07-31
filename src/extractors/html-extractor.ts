import { Extractor } from "../extractor"
import { ExtractorOptions } from "../options"

export class HtmlExtractor extends Extractor {

  public static handle = "html"
  public static exts = [".html", ".xml", ".jade", ".pug"]

  constructor(options: ExtractorOptions) {
    super(options)
  }

  public get preBrick() { return "(?:src|href)\\s*=\\s*" }

}

export default HtmlExtractor
