/*! @github/auto-complete-element 3.6.2
 * https://github.com/github/auto-complete-element
 * MIT License
 *
 * Vendored from npm bundle.js with ES module export block removed
 * for Sprockets compatibility. To update:
 *   curl -sL 'https://cdn.jsdelivr.net/npm/@github/auto-complete-element@3.6.2/dist/bundle.js' \
 *     | sed '/^export {/,/^};/d' > vendor/assets/javascripts/auto-complete-element.js
 */
var __defProp = Object.defineProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });

// node_modules/@github/combobox-nav/dist/index.js
var Combobox = class {
  constructor(input, list, { tabInsertsSuggestions, defaultFirstOption, scrollIntoViewOptions } = {}) {
    this.input = input;
    this.list = list;
    this.tabInsertsSuggestions = tabInsertsSuggestions !== null && tabInsertsSuggestions !== void 0 ? tabInsertsSuggestions : true;
    this.defaultFirstOption = defaultFirstOption !== null && defaultFirstOption !== void 0 ? defaultFirstOption : false;
    this.scrollIntoViewOptions = scrollIntoViewOptions;
    this.isComposing = false;
    if (!list.id) {
      list.id = `combobox-${Math.random().toString().slice(2, 6)}`;
    }
    this.ctrlBindings = !!navigator.userAgent.match(/Macintosh/);
    this.keyboardEventHandler = (event) => keyboardBindings(event, this);
    this.compositionEventHandler = (event) => trackComposition(event, this);
    this.inputHandler = this.clearSelection.bind(this);
    input.setAttribute("role", "combobox");
    input.setAttribute("aria-controls", list.id);
    input.setAttribute("aria-expanded", "false");
    input.setAttribute("aria-autocomplete", "list");
    input.setAttribute("aria-haspopup", "listbox");
  }
  destroy() {
    this.clearSelection();
    this.stop();
    this.input.removeAttribute("role");
    this.input.removeAttribute("aria-controls");
    this.input.removeAttribute("aria-expanded");
    this.input.removeAttribute("aria-autocomplete");
    this.input.removeAttribute("aria-haspopup");
  }
  start() {
    this.input.setAttribute("aria-expanded", "true");
    this.input.addEventListener("compositionstart", this.compositionEventHandler);
    this.input.addEventListener("compositionend", this.compositionEventHandler);
    this.input.addEventListener("input", this.inputHandler);
    this.input.addEventListener("keydown", this.keyboardEventHandler);
    this.list.addEventListener("click", commitWithElement);
    this.indicateDefaultOption();
  }
  stop() {
    this.clearSelection();
    this.input.setAttribute("aria-expanded", "false");
    this.input.removeEventListener("compositionstart", this.compositionEventHandler);
    this.input.removeEventListener("compositionend", this.compositionEventHandler);
    this.input.removeEventListener("input", this.inputHandler);
    this.input.removeEventListener("keydown", this.keyboardEventHandler);
    this.list.removeEventListener("click", commitWithElement);
  }
  indicateDefaultOption() {
    var _a;
    if (this.defaultFirstOption) {
      (_a = Array.from(this.list.querySelectorAll('[role="option"]:not([aria-disabled="true"])')).filter(visible)[0]) === null || _a === void 0 ? void 0 : _a.setAttribute("data-combobox-option-default", "true");
    }
  }
  navigate(indexDiff = 1) {
    const focusEl = Array.from(this.list.querySelectorAll('[aria-selected="true"]')).filter(visible)[0];
    const els = Array.from(this.list.querySelectorAll('[role="option"]')).filter(visible);
    const focusIndex = els.indexOf(focusEl);
    if (focusIndex === els.length - 1 && indexDiff === 1 || focusIndex === 0 && indexDiff === -1) {
      this.clearSelection();
      this.input.focus();
      return;
    }
    let indexOfItem = indexDiff === 1 ? 0 : els.length - 1;
    if (focusEl && focusIndex >= 0) {
      const newIndex = focusIndex + indexDiff;
      if (newIndex >= 0 && newIndex < els.length)
        indexOfItem = newIndex;
    }
    const target = els[indexOfItem];
    if (!target)
      return;
    for (const el of els) {
      el.removeAttribute("data-combobox-option-default");
      if (target === el) {
        this.input.setAttribute("aria-activedescendant", target.id);
        target.setAttribute("aria-selected", "true");
        fireSelectEvent(target);
        target.scrollIntoView(this.scrollIntoViewOptions);
      } else {
        el.removeAttribute("aria-selected");
      }
    }
  }
  clearSelection() {
    this.input.removeAttribute("aria-activedescendant");
    for (const el of this.list.querySelectorAll('[aria-selected="true"]')) {
      el.removeAttribute("aria-selected");
    }
    this.indicateDefaultOption();
  }
};
__name(Combobox, "Combobox");
function keyboardBindings(event, combobox) {
  if (event.shiftKey || event.metaKey || event.altKey)
    return;
  if (!combobox.ctrlBindings && event.ctrlKey)
    return;
  if (combobox.isComposing)
    return;
  switch (event.key) {
    case "Enter":
      if (commit(combobox.input, combobox.list)) {
        event.preventDefault();
      }
      break;
    case "Tab":
      if (combobox.tabInsertsSuggestions && commit(combobox.input, combobox.list)) {
        event.preventDefault();
      }
      break;
    case "Escape":
      combobox.clearSelection();
      break;
    case "ArrowDown":
      combobox.navigate(1);
      event.preventDefault();
      break;
    case "ArrowUp":
      combobox.navigate(-1);
      event.preventDefault();
      break;
    case "n":
      if (combobox.ctrlBindings && event.ctrlKey) {
        combobox.navigate(1);
        event.preventDefault();
      }
      break;
    case "p":
      if (combobox.ctrlBindings && event.ctrlKey) {
        combobox.navigate(-1);
        event.preventDefault();
      }
      break;
    default:
      if (event.ctrlKey)
        break;
      combobox.clearSelection();
  }
}
__name(keyboardBindings, "keyboardBindings");
function commitWithElement(event) {
  if (!(event.target instanceof Element))
    return;
  const target = event.target.closest('[role="option"]');
  if (!target)
    return;
  if (target.getAttribute("aria-disabled") === "true")
    return;
  fireCommitEvent(target, { event });
}
__name(commitWithElement, "commitWithElement");
function commit(input, list) {
  const target = list.querySelector('[aria-selected="true"], [data-combobox-option-default="true"]');
  if (!target)
    return false;
  if (target.getAttribute("aria-disabled") === "true")
    return true;
  target.click();
  return true;
}
__name(commit, "commit");
function fireCommitEvent(target, detail) {
  target.dispatchEvent(new CustomEvent("combobox-commit", { bubbles: true, detail }));
}
__name(fireCommitEvent, "fireCommitEvent");
function fireSelectEvent(target) {
  target.dispatchEvent(new Event("combobox-select", { bubbles: true }));
}
__name(fireSelectEvent, "fireSelectEvent");
function visible(el) {
  return !el.hidden && !(el instanceof HTMLInputElement && el.type === "hidden") && (el.offsetWidth > 0 || el.offsetHeight > 0);
}
__name(visible, "visible");
function trackComposition(event, combobox) {
  combobox.isComposing = event.type === "compositionstart";
  const list = document.getElementById(combobox.input.getAttribute("aria-controls") || "");
  if (!list)
    return;
  combobox.clearSelection();
}
__name(trackComposition, "trackComposition");

// dist/debounce.js
function debounce(callback, wait = 0) {
  let timeout;
  return function(...Rest) {
    clearTimeout(timeout);
    timeout = window.setTimeout(() => {
      clearTimeout(timeout);
      callback(...Rest);
    }, wait);
  };
}
__name(debounce, "debounce");

// dist/autocomplete.js
var SCREEN_READER_DELAY = window.testScreenReaderDelay || 100;
var Autocomplete = class {
  constructor(container, input, results, autoselectEnabled = false) {
    var _a;
    this.container = container;
    this.input = input;
    this.results = results;
    this.combobox = new Combobox(input, results, {
      defaultFirstOption: autoselectEnabled
    });
    this.feedback = container.getRootNode().getElementById(`${this.results.id}-feedback`);
    this.autoselectEnabled = autoselectEnabled;
    this.clearButton = container.getRootNode().getElementById(`${this.input.id || this.input.name}-clear`);
    this.clientOptions = results.querySelectorAll("[role=option]");
    if (this.feedback) {
      this.feedback.setAttribute("aria-live", "polite");
      this.feedback.setAttribute("aria-atomic", "true");
    }
    if (this.clearButton && !this.clearButton.getAttribute("aria-label")) {
      const labelElem = document.querySelector(`label[for="${this.input.name}"]`);
      this.clearButton.setAttribute("aria-label", `clear:`);
      this.clearButton.setAttribute("aria-labelledby", `${this.clearButton.id} ${(labelElem === null || labelElem === void 0 ? void 0 : labelElem.id) || ""}`);
    }
    if (!this.input.getAttribute("aria-expanded")) {
      this.input.setAttribute("aria-expanded", "false");
    }
    if (this.results.popover) {
      if (this.results.matches(":popover-open")) {
        this.results.hidePopover();
      }
    } else {
      this.results.hidden = true;
    }
    if (!this.results.getAttribute("aria-label")) {
      this.results.setAttribute("aria-label", "results");
    }
    this.input.setAttribute("autocomplete", "off");
    this.input.setAttribute("spellcheck", "false");
    this.interactingWithList = false;
    this.onInputChange = debounce(this.onInputChange.bind(this), 300);
    this.onResultsMouseDown = this.onResultsMouseDown.bind(this);
    this.onInputBlur = this.onInputBlur.bind(this);
    this.onInputFocus = this.onInputFocus.bind(this);
    this.onKeydown = this.onKeydown.bind(this);
    this.onCommit = this.onCommit.bind(this);
    this.handleClear = this.handleClear.bind(this);
    this.input.addEventListener("keydown", this.onKeydown);
    this.input.addEventListener("focus", this.onInputFocus);
    this.input.addEventListener("blur", this.onInputBlur);
    this.input.addEventListener("input", this.onInputChange);
    this.results.addEventListener("mousedown", this.onResultsMouseDown);
    this.results.addEventListener("combobox-commit", this.onCommit);
    (_a = this.clearButton) === null || _a === void 0 ? void 0 : _a.addEventListener("click", this.handleClear);
  }
  destroy() {
    this.input.removeEventListener("keydown", this.onKeydown);
    this.input.removeEventListener("focus", this.onInputFocus);
    this.input.removeEventListener("blur", this.onInputBlur);
    this.input.removeEventListener("input", this.onInputChange);
    this.results.removeEventListener("mousedown", this.onResultsMouseDown);
    this.results.removeEventListener("combobox-commit", this.onCommit);
  }
  handleClear(event) {
    event.preventDefault();
    if (this.input.getAttribute("aria-expanded") === "true") {
      this.input.setAttribute("aria-expanded", "false");
      this.updateFeedbackForScreenReaders("Results hidden.");
    }
    this.input.value = "";
    this.container.value = "";
    this.input.focus();
    this.input.dispatchEvent(new Event("change"));
    this.close();
  }
  onKeydown(event) {
    if (event.key === "Escape" && this.container.open) {
      this.close();
      event.stopPropagation();
      event.preventDefault();
    } else if (event.altKey && event.key === "ArrowUp" && this.container.open) {
      this.close();
      event.stopPropagation();
      event.preventDefault();
    } else if (event.altKey && event.key === "ArrowDown" && !this.container.open) {
      if (!this.input.value.trim())
        return;
      this.open();
      event.stopPropagation();
      event.preventDefault();
    }
  }
  onInputFocus() {
    if (this.interactingWithList)
      return;
    this.fetchResults();
  }
  onInputBlur() {
    if (this.interactingWithList)
      return;
    this.close();
  }
  onCommit({ target }) {
    const selected = target;
    if (!(selected instanceof HTMLElement))
      return;
    this.close();
    if (selected instanceof HTMLAnchorElement)
      return;
    const value = selected.getAttribute("data-autocomplete-value") || selected.textContent;
    this.updateFeedbackForScreenReaders(`${selected.textContent || ""} selected.`);
    this.container.value = value;
    if (!value) {
      this.updateFeedbackForScreenReaders(`Results hidden.`);
    }
  }
  onResultsMouseDown() {
    this.interactingWithList = true;
  }
  onInputChange() {
    if (this.feedback && this.feedback.textContent) {
      this.feedback.textContent = "";
    }
    this.container.removeAttribute("value");
    this.fetchResults();
  }
  identifyOptions() {
    let id = 0;
    for (const el of this.results.querySelectorAll('[role="option"]:not([id])')) {
      el.id = `${this.results.id}-option-${id++}`;
    }
  }
  updateFeedbackForScreenReaders(inputString) {
    setTimeout(() => {
      if (this.feedback) {
        this.feedback.textContent = inputString;
      }
    }, SCREEN_READER_DELAY);
  }
  fetchResults() {
    const query = this.input.value.trim();
    if (!query && !this.container.fetchOnEmpty) {
      this.close();
      return;
    }
    const src = this.container.src;
    if (!src)
      return;
    const url = new URL(src, window.location.href);
    const params = new URLSearchParams(url.search.slice(1));
    params.append("q", query);
    url.search = params.toString();
    this.container.dispatchEvent(new CustomEvent("loadstart"));
    this.container.fetchResult(url).then((html) => {
      this.results.innerHTML = html;
      this.identifyOptions();
      this.combobox.indicateDefaultOption();
      const allNewOptions = this.results.querySelectorAll('[role="option"]');
      const hasResults = !!allNewOptions.length;
      const numOptions = allNewOptions.length;
      const [firstOption] = allNewOptions;
      const firstOptionValue = firstOption === null || firstOption === void 0 ? void 0 : firstOption.textContent;
      if (this.autoselectEnabled && firstOptionValue) {
        this.updateFeedbackForScreenReaders(`${numOptions} results. ${firstOptionValue} is the top result: Press Enter to activate.`);
      } else {
        this.updateFeedbackForScreenReaders(`${numOptions || "No"} results.`);
      }
      hasResults ? this.open() : this.close();
      this.container.dispatchEvent(new CustomEvent("load"));
      this.container.dispatchEvent(new CustomEvent("loadend"));
    }).catch(() => {
      this.container.dispatchEvent(new CustomEvent("error"));
      this.container.dispatchEvent(new CustomEvent("loadend"));
    });
  }
  open() {
    const isHidden = this.results.popover ? !this.results.matches(":popover-open") : this.results.hidden;
    if (isHidden) {
      this.combobox.start();
      if (this.results.popover) {
        this.results.showPopover();
      } else {
        this.results.hidden = false;
      }
    }
    this.container.open = true;
    this.interactingWithList = true;
  }
  close() {
    const isVisible = this.results.popover ? this.results.matches(":popover-open") : !this.results.hidden;
    if (isVisible) {
      this.combobox.stop();
      if (this.results.popover) {
        this.results.hidePopover();
      } else {
        this.results.hidden = true;
      }
    }
    this.container.open = false;
    this.interactingWithList = false;
  }
};
__name(Autocomplete, "Autocomplete");

// dist/auto-complete-element.js
var __classPrivateFieldGet = function(receiver, state2, kind, f) {
  if (kind === "a" && !f)
    throw new TypeError("Private accessor was defined without a getter");
  if (typeof state2 === "function" ? receiver !== state2 || !f : !state2.has(receiver))
    throw new TypeError("Cannot read private member from an object whose class did not declare it");
  return kind === "m" ? f : kind === "a" ? f.call(receiver) : f ? f.value : state2.get(receiver);
};
var __classPrivateFieldSet = function(receiver, state2, value, kind, f) {
  if (kind === "m")
    throw new TypeError("Private method is not writable");
  if (kind === "a" && !f)
    throw new TypeError("Private accessor was defined without a setter");
  if (typeof state2 === "function" ? receiver !== state2 || !f : !state2.has(receiver))
    throw new TypeError("Cannot write private member to an object whose class did not declare it");
  return kind === "a" ? f.call(receiver, value) : f ? f.value = value : state2.set(receiver, value), value;
};
var __rest = function(s, e) {
  var t = {};
  for (var p in s)
    if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
      t[p] = s[p];
  if (s != null && typeof Object.getOwnPropertySymbols === "function")
    for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
      if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
        t[p[i]] = s[p[i]];
    }
  return t;
};
var _AutoCompleteElement_instances;
var _AutoCompleteElement_forElement;
var _AutoCompleteElement_inputElement;
var _AutoCompleteElement_reattachState;
var _AutoCompleteElement_requestController;
var HTMLElement2 = globalThis.HTMLElement || null;
var AutoCompleteEvent = class extends Event {
  constructor(type, _a) {
    var { relatedTarget } = _a, init = __rest(_a, ["relatedTarget"]);
    super(type, init);
    this.relatedTarget = relatedTarget;
  }
};
__name(AutoCompleteEvent, "AutoCompleteEvent");
var state = /* @__PURE__ */ new WeakMap();
var cspTrustedTypesPolicyPromise = null;
var AutoCompleteElement = class extends HTMLElement2 {
  constructor() {
    super(...arguments);
    _AutoCompleteElement_instances.add(this);
    _AutoCompleteElement_forElement.set(this, null);
    _AutoCompleteElement_inputElement.set(this, null);
    _AutoCompleteElement_requestController.set(this, void 0);
  }
  static define(tag = "auto-complete", registry = customElements) {
    registry.define(tag, this);
    return this;
  }
  static setCSPTrustedTypesPolicy(policy) {
    cspTrustedTypesPolicyPromise = policy === null ? policy : Promise.resolve(policy);
  }
  get forElement() {
    var _a;
    if ((_a = __classPrivateFieldGet(this, _AutoCompleteElement_forElement, "f")) === null || _a === void 0 ? void 0 : _a.isConnected) {
      return __classPrivateFieldGet(this, _AutoCompleteElement_forElement, "f");
    }
    const id = this.getAttribute("for");
    const root2 = this.getRootNode();
    if (id && (root2 instanceof Document || root2 instanceof ShadowRoot)) {
      return root2.getElementById(id);
    }
    return null;
  }
  set forElement(element) {
    __classPrivateFieldSet(this, _AutoCompleteElement_forElement, element, "f");
    this.setAttribute("for", "");
  }
  get inputElement() {
    var _a;
    if ((_a = __classPrivateFieldGet(this, _AutoCompleteElement_inputElement, "f")) === null || _a === void 0 ? void 0 : _a.isConnected) {
      return __classPrivateFieldGet(this, _AutoCompleteElement_inputElement, "f");
    }
    return this.querySelector("input");
  }
  set inputElement(input) {
    __classPrivateFieldSet(this, _AutoCompleteElement_inputElement, input, "f");
    __classPrivateFieldGet(this, _AutoCompleteElement_instances, "m", _AutoCompleteElement_reattachState).call(this);
  }
  connectedCallback() {
    if (!this.isConnected)
      return;
    __classPrivateFieldGet(this, _AutoCompleteElement_instances, "m", _AutoCompleteElement_reattachState).call(this);
    new MutationObserver(() => {
      if (!state.get(this)) {
        __classPrivateFieldGet(this, _AutoCompleteElement_instances, "m", _AutoCompleteElement_reattachState).call(this);
      }
    }).observe(this, { subtree: true, childList: true });
  }
  disconnectedCallback() {
    const autocomplete = state.get(this);
    if (autocomplete) {
      autocomplete.destroy();
      state.delete(this);
    }
  }
  get src() {
    return this.getAttribute("src") || "";
  }
  set src(url) {
    this.setAttribute("src", url);
  }
  get value() {
    return this.getAttribute("value") || "";
  }
  set value(value) {
    this.setAttribute("value", value);
  }
  get open() {
    return this.hasAttribute("open");
  }
  set open(value) {
    if (value) {
      this.setAttribute("open", "");
    } else {
      this.removeAttribute("open");
    }
  }
  get fetchOnEmpty() {
    return this.hasAttribute("fetch-on-empty");
  }
  set fetchOnEmpty(fetchOnEmpty) {
    this.toggleAttribute("fetch-on-empty", fetchOnEmpty);
  }
  async fetchResult(url) {
    var _a;
    (_a = __classPrivateFieldGet(this, _AutoCompleteElement_requestController, "f")) === null || _a === void 0 ? void 0 : _a.abort();
    const { signal } = __classPrivateFieldSet(this, _AutoCompleteElement_requestController, new AbortController(), "f");
    const res = await fetch(url.toString(), {
      signal,
      headers: {
        Accept: "text/fragment+html"
      }
    });
    if (!res.ok) {
      throw new Error(await res.text());
    }
    if (cspTrustedTypesPolicyPromise) {
      const cspTrustedTypesPolicy = await cspTrustedTypesPolicyPromise;
      return cspTrustedTypesPolicy.createHTML(await res.text(), res);
    }
    return await res.text();
  }
  static get observedAttributes() {
    return ["open", "value", "for"];
  }
  attributeChangedCallback(name, oldValue, newValue) {
    var _a, _b;
    if (oldValue === newValue)
      return;
    const autocomplete = state.get(this);
    if (!autocomplete)
      return;
    if (this.forElement !== ((_a = state.get(this)) === null || _a === void 0 ? void 0 : _a.results) || this.inputElement !== ((_b = state.get(this)) === null || _b === void 0 ? void 0 : _b.input)) {
      __classPrivateFieldGet(this, _AutoCompleteElement_instances, "m", _AutoCompleteElement_reattachState).call(this);
    }
    switch (name) {
      case "open":
        newValue === null ? autocomplete.close() : autocomplete.open();
        break;
      case "value":
        if (newValue !== null) {
          autocomplete.input.value = newValue;
        }
        this.dispatchEvent(new AutoCompleteEvent("auto-complete-change", {
          bubbles: true,
          relatedTarget: autocomplete.input
        }));
        break;
    }
  }
};
__name(AutoCompleteElement, "AutoCompleteElement");
_AutoCompleteElement_forElement = /* @__PURE__ */ new WeakMap(), _AutoCompleteElement_inputElement = /* @__PURE__ */ new WeakMap(), _AutoCompleteElement_requestController = /* @__PURE__ */ new WeakMap(), _AutoCompleteElement_instances = /* @__PURE__ */ new WeakSet(), _AutoCompleteElement_reattachState = /* @__PURE__ */ __name(function _AutoCompleteElement_reattachState2() {
  var _a;
  (_a = state.get(this)) === null || _a === void 0 ? void 0 : _a.destroy();
  const { forElement, inputElement } = this;
  if (!forElement || !inputElement)
    return;
  const autoselectEnabled = this.getAttribute("data-autoselect") === "true";
  state.set(this, new Autocomplete(this, inputElement, forElement, autoselectEnabled));
  forElement.setAttribute("role", "listbox");
}, "_AutoCompleteElement_reattachState");

// dist/auto-complete-element-define.js
var root = typeof globalThis !== "undefined" ? globalThis : window;
try {
  root.AutocompleteElement = root.AutoCompleteElement = AutoCompleteElement.define();
} catch (e) {
  if (!(root.DOMException && e instanceof DOMException && e.name === "NotSupportedError") && !(e instanceof ReferenceError)) {
    throw e;
  }
}

// dist/index.js
var dist_default = AutoCompleteElement;
// ES module exports removed — Sprockets loads this as a plain <script>,
// which can't use `export`. The custom element self-registers via
// AutoCompleteElement.define() above, so no explicit exports are needed.
// export {
//   AutoCompleteElement,
//   AutoCompleteEvent,
//   dist_default as default
// };
