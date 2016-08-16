class TimeoutError extends Error {
  constructor(tag, originTag, timeout) {
    super()
    this.tag = tag;
    this.originTag = originTag;
    this.timeout = timeout;
    if (this.originTag) {
      var originText = `(by ${this.originTag}) `;
    }
    this.message = `Timeout for tag '${this.tag} ${originText}after ${this.timeout}ms`;
  }
}


class Resolver {
  constructor(options) {
    options = options || {};
    this.map = {};
    this.timeout = options.timeout;
  }

  getEntry(tag) {
    return this.map[tag];
  }

  createEntry(tag, err, data) {
    return this.map[tag] = {
      err,
      data,
      queue: []
    };
  }

  resolveEntry(entry, err, data) {
    if (entry.timer != null) {
      clearTimeout(entry.timer);
      entry.timer = null;
    }
    entry.err = err;
    entry.data = data;
    while (entry.queue.length > 0) {
      let done = entry.queue.shift();
      done(entry.err, entry.data);
    }
    entry.resolved = true;
  }

  pull(tag, originTag, done) {
    let entry = this.map[tag];
    if (entry != null) {
      if (entry.resolved) {
        done(entry.err, entry.data);
        return;
      }
    } else {
      entry = this.createEntry(tag);
    }
    entry.queue.push(done);
    if (this.timeout != null) {
      let timerFn = () => this.resolveEntry(entry, new TimeoutError(tag, originTag, this.timeout));
      entry.timer = setTimeout(timerFn, this.timeout);
    }
  }

  push(tag, err, data) {
    let entry = this.map[tag];
    if (entry != null) {
      if (entry.resolved) {
        if (!entry.err) {
          throw new Error(`duplicate tag: '${tag}'`);
        }
      } else {
        this.resolveEntry(entry, err, data);
      }
    } else {
      entry = this.createEntry(tag, err, data);
      entry.resolved = true;
    }
  }
}

let factory = options => new Resolver(options);

factory.Resolver = Resolver;
factory.TimeoutError = TimeoutError;

export default factory;
