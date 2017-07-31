import { Extractor } from "../extractor"
import { ExtractorOptions } from "../options"

export class ScriptExtractor extends Extractor {

  public static handle = "script"
  public static exts = [".js", ".jsx", ".ts", ".tsx", ".coffee"]

  constructor(options: ExtractorOptions) {
    super(options)
  }

  // if the url appears inside a string, its quotes will be escaped
  public get openBrick() { return '\\\\?[\'"]' }
}

export default ScriptExtractor
