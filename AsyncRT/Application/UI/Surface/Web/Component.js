(() => {
    const tagName = __ASYNC_WEBUI_TAG_NAME__;
    const styleText = __ASYNC_WEBUI_STYLE_TEXT__;
    const layoutHTML = __ASYNC_WEBUI_LAYOUT_HTML__;
    const propertyNames = __ASYNC_WEBUI_PROPERTY_NAMES__;
    const nativeInvokeAction = __ASYNC_WEBUI_INVOKE_ACTION_NAME__;
    const stateAttributeName = 'data-async-webui-state';
    const componentIDAttributeName = 'data-async-webui-id';

    if (customElements.get(tagName))
        return;

    const layoutParts = [];
    let layoutIndex = 0;
    for (const match of layoutHTML.matchAll(/\{\{\s*([A-Za-z_][A-Za-z0-9_]*)\s*\}\}/g)) {
        if (match.index > layoutIndex)
            layoutParts.push(layoutHTML.slice(layoutIndex, match.index));

        layoutParts.push({ propertyName: match[1] });
        layoutIndex = match.index + match[0].length;
    }

    if (layoutIndex < layoutHTML.length)
        layoutParts.push(layoutHTML.slice(layoutIndex));

    const styleTemplate = document.createElement('style');
    styleTemplate.textContent = styleText;

    const valueToText = (value) => {
        if (value === null || value === undefined)
            return '';
        if (typeof value === 'object')
            return JSON.stringify(value);

        return String(value);
    };

    const escapeHTML = (value) => valueToText(value).replace(/[&<>"']/g, (character) => ({
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;'
    })[character]);

    const parseState = (element) => {
        const rawState = element.getAttribute(stateAttributeName);
        if (rawState === null || rawState.length === 0)
            return {};

        try {
            const state = JSON.parse(rawState);
            return state && typeof state === 'object' && !Array.isArray(state) ? state : {};
        } catch (error) {
            console.error('Invalid AsyncWebUI component state for', tagName, error);
            return {};
        }
    };

    const eventPayload = (event) => {
        const target = event.target instanceof Element ? event.target : null;
        const payload = [event.type, event.bubbles, event.cancelable];

        if (target !== null) {
            payload.push(
                target.tagName.toLowerCase(),
                target.id || '',
                typeof target.className === 'string' ? target.className : ''
            );

            if ('value' in target)
                payload.push(target.value);
        }

        return payload;
    };

    class Component extends HTMLElement {
        constructor() {
            super();
            this.attachShadow({ mode: 'open' });
            this.styleNode = styleTemplate.cloneNode(true);
            this.shadowRoot.append(this.styleNode);
            this.componentID = '';
            this.state = {};
            this.nativeListeners = [];
        }

        connectedCallback() {
            this.componentID = this.getAttribute(componentIDAttributeName) || '';
            this.state = parseState(this);
            this.removeAttribute(stateAttributeName);
            if (window.AsyncRT && window.AsyncRT.__components)
                window.AsyncRT.__components.register(this.componentID, this);
            this.render();
        }

        disconnectedCallback() {
            if (window.AsyncRT && window.AsyncRT.__components)
                window.AsyncRT.__components.unregister(this.componentID, this);
            this.clearNativeListeners();
        }

        setState(state) {
            const nextState = {};
            for (const propertyName of propertyNames)
                if (Object.prototype.hasOwnProperty.call(state, propertyName))
                    nextState[propertyName] = state[propertyName];

            this.state = nextState;
            this.render();
        }

        clearNativeListeners() {
            for (const listener of this.nativeListeners)
                listener.element.removeEventListener(listener.eventName, listener.callback);

            this.nativeListeners = [];
        }

        render() {
            if (!this.shadowRoot)
                return;

            let renderedHTML = '';
            for (const part of layoutParts)
                renderedHTML += typeof part === 'string' ? part : escapeHTML(this.state[part.propertyName]);

            const template = document.createElement('template');
            template.innerHTML = renderedHTML;

            this.clearNativeListeners();
            while (this.styleNode.nextSibling)
                this.styleNode.nextSibling.remove();
            this.shadowRoot.append(template.content);
            this.bindNativeActions();
        }

        bindNativeActions() {
            const bindElement = (element) => {
                if (typeof element.hasAttributes !== 'function' || !element.hasAttributes())
                    return;

                for (let index = element.attributes.length - 1; index >= 0; index--) {
                    const attribute = element.attributes[index];
                    const name = attribute.name;
                    if ((name.charCodeAt(0) | 32) !== 111 || (name.charCodeAt(1) | 32) !== 110)
                        continue;

                    const selector = attribute.value.trim();
                    if (selector.length === 0)
                        continue;

                    const eventName = name.slice(2);
                    const wantsEvent = selector.includes(':');
                    element.removeAttribute(name);

                    const callback = (event) => {
                        if (event.cancelable)
                            event.preventDefault();

                        const payload = wantsEvent
                            ? [this.componentID, selector, eventPayload(event)]
                            : [this.componentID, selector];

                        window.AsyncRT.invoke(nativeInvokeAction, payload).then((response) => {
                            if (response && response.error) {
                                const reason = response.error.description || response.error.reason || response.error.className || 'AsyncWebUI native action failed';
                                throw new Error(reason);
                            }

                            if (response && typeof response === 'object')
                                this.setState(response);
                        });
                    };

                    element.addEventListener(eventName, callback);
                    this.nativeListeners.push({ element, eventName, callback });
                }
            }

            bindElement(this.shadowRoot);
            for (const element of this.shadowRoot.querySelectorAll('*'))
                bindElement(element);
        }
    }

    customElements.define(tagName, Component);
})();
