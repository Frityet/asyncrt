(() => {
    const tagName = __ASYNC_WEBUI_TAG_NAME__;
    const styleText = __ASYNC_WEBUI_STYLE_TEXT__;
    const layoutHTML = __ASYNC_WEBUI_LAYOUT_HTML__;
    const propertyNames = __ASYNC_WEBUI_PROPERTY_NAMES__;
    const invokeActionName = __ASYNC_WEBUI_INVOKE_ACTION_NAME__;
    const updateEventName = __ASYNC_WEBUI_UPDATE_EVENT_NAME__;
    const stateAttributeName = 'data-async-webui-state';
    const componentIDAttributeName = 'data-async-webui-id';
    const nativeActionPattern = /^\[self\s+([A-Za-z_][A-Za-z0-9_:]*)\]$/;

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
        const payload = {
            type: event.type,
            bubbles: event.bubbles,
            cancelable: event.cancelable
        };

        if (target !== null) {
            payload.target = {
                tagName: target.tagName.toLowerCase(),
                id: target.id || '',
                className: typeof target.className === 'string' ? target.className : ''
            };

            if ('value' in target)
                payload.target.value = target.value;
        }

        return payload;
    };

    class Component extends HTMLElement {
        static get observedAttributes() {
            return [stateAttributeName];
        }

        constructor() {
            super();
            this.attachShadow({ mode: 'open' });
            this.state = {};
            this.nativeListeners = [];
            this.isSyncingStateAttribute = false;
            this.handleNativeUpdate = (event) => {
                const detail = event.detail;
                if (!detail || String(detail.componentID || '') !== this.componentID)
                    return;

                if (detail.state && typeof detail.state === 'object')
                    this.setState(detail.state);
            };
        }

        get componentID() {
            return this.getAttribute(componentIDAttributeName) || '';
        }

        connectedCallback() {
            this.state = parseState(this);
            window.addEventListener(updateEventName, this.handleNativeUpdate);
            this.render();
        }

        disconnectedCallback() {
            window.removeEventListener(updateEventName, this.handleNativeUpdate);
            this.clearNativeListeners();
        }

        attributeChangedCallback(name, oldValue, newValue) {
            if (name !== stateAttributeName || oldValue === newValue)
                return;
            if (this.isSyncingStateAttribute)
                return;

            this.state = parseState(this);
            this.render();
        }

        setState(state) {
            const nextState = {};
            for (const propertyName of propertyNames)
                if (Object.prototype.hasOwnProperty.call(state, propertyName))
                    nextState[propertyName] = state[propertyName];

            for (const [key, value] of Object.entries(state))
                if (!Object.prototype.hasOwnProperty.call(nextState, key))
                    nextState[key] = value;

            this.state = nextState;

            const stateJSON = JSON.stringify(this.state);
            if (this.getAttribute(stateAttributeName) !== stateJSON) {
                this.isSyncingStateAttribute = true;
                try {
                    this.setAttribute(stateAttributeName, stateJSON);
                } finally {
                    this.isSyncingStateAttribute = false;
                }
            }

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
            this.shadowRoot.replaceChildren(styleTemplate.cloneNode(true), template.content.cloneNode(true));
            this.bindNativeActions();
        }

        bindNativeActions() {
            const elements = [this.shadowRoot, ...this.shadowRoot.querySelectorAll('*')];

            for (const element of elements) {
                if (typeof element.hasAttributes !== 'function' || !element.hasAttributes())
                    continue;

                for (const attribute of Array.from(element.attributes)) {
                    if (!attribute.name.toLowerCase().startsWith('on'))
                        continue;

                    const match = attribute.value.trim().match(nativeActionPattern);
                    if (!match)
                        continue;

                    const eventName = attribute.name.slice(2).toLowerCase();
                    const selector = match[1];
                    element.removeAttribute(attribute.name);

                    const callback = async (event) => {
                        if (event.cancelable)
                            event.preventDefault();

                        const response = await window.AsyncRT.invoke(invokeActionName, {
                            componentID: this.componentID,
                            selector,
                            event: eventPayload(event)
                        });

                        if (response && response.error) {
                            const reason = response.error.description || response.error.reason || response.error.className || 'AsyncWebUI native action failed';
                            throw new Error(reason);
                        }

                        if (response && response.state && typeof response.state === 'object')
                            this.setState(response.state);
                    };

                    element.addEventListener(eventName, callback);
                    this.nativeListeners.push({ element, eventName, callback });
                }
            }
        }
    }

    customElements.define(tagName, Component);
})();
