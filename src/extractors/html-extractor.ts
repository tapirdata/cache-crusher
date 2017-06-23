import { ExtractorOptions } from "../options"
import Extractor from "./extractor"

export class HtmlExtractor extends Extractor {

  public static handle = "html"
  public static exts = [".html", ".xml", ".jade"]

  constructor(options: ExtractorOptions) {
    super(options)
  }

  public get preBrick() { return "(?:src|href)\\s*=\\s*" }

}

export default HtmlExtractor
