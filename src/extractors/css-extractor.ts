import { ExtractorOptions } from "../options"
import Extractor from "./extractor"

export class CssExtractor extends Extractor {

  public static handle = "css"
  public static exts = [".css"]

  constructor(options: ExtractorOptions) {
    super(options)
  }

  public get preBrick() { return '(?:url)\\s*\\(\\s*' }
}

export default CssExtractor


