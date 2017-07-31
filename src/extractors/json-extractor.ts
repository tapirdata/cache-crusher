import { Extractor } from "../extractor"
import { ExtractorOptions } from "../options"

export class JsonExtractor extends Extractor {

  public static handle = "json"
  public static exts = [".json"]

  constructor(options: ExtractorOptions) {
    super(options)
  }

}

export default JsonExtractor
