import Extractor from "./extractor"
import { ExtractorOptions } from "./extractor"

export class HtmlExtractor extends Extractor {

  constructor(options: ExtractorOptions) {
    super(options)
  }

}

(HtmlExtractor as any).handle = "html";
(HtmlExtractor as any).exts = [".html", ".xml", ".jade"];

(HtmlExtractor.prototype as any).preBrick = "(?:src|href)\\s*=\\s*"

export default HtmlExtractor
