(() => {
    const bridge = window.AsyncRT || {};

    bridge.__resolve = () => {};
    bridge.__emit = (name, payload) => {
        window.dispatchEvent(new CustomEvent(name, { detail: payload }));
    };

    bridge.__startHTTPCommandPolling = () => {
        if (bridge.__httpCommandPollingStarted)
            return;

        bridge.__httpCommandPollingStarted = true;
        let lastCommandID = 0;
        let active = true;

        const postEvaluationResult = async (requestID, ok, value) => {
            try {
                await fetch('/__asyncrt/evaluate-result', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify([requestID, ok, value === undefined ? null : value])
                });
            } catch (error) {
                console.error('AsyncRT failed to post evaluation result', error);
            }
        };

        const errorPayload = (error) => ({
            name: error && error.name ? String(error.name) : 'Error',
            message: error && error.message ? String(error.message) : String(error),
            stack: error && error.stack ? String(error.stack) : ''
        });

        const evaluateCommand = async (command) => {
            try {
                const value = await (0, eval)(command.script);
                if (typeof command.requestID === 'string')
                    await postEvaluationResult(command.requestID, true, value);
            } catch (error) {
                console.error('AsyncRT command failed', error, command.script);
                if (typeof command.requestID === 'string')
                    await postEvaluationResult(command.requestID, false, errorPayload(error));
            }
        };

        const poll = async () => {
            if (!active)
                return;

            let didReceiveCommands = false;
            try {
                const response = await fetch('/__asyncrt/events?since=' + encodeURIComponent(String(lastCommandID)), {
                    cache: 'no-store'
                });
                if (!response.ok)
                    throw new Error('AsyncRT command poll failed with HTTP ' + response.status);

                const commands = await response.json();
                if (Array.isArray(commands)) {
                    for (const command of commands) {
                        if (!command || typeof command !== 'object')
                            continue;

                        if (typeof command.id === 'number' && command.id > lastCommandID)
                            lastCommandID = command.id;

                        if (typeof command.script !== 'string')
                            continue;

                        didReceiveCommands = true;
                        await evaluateCommand(command);
                    }
                }
            } catch (error) {
                console.error('AsyncRT command polling failed', error);
            }

            setTimeout(poll, didReceiveCommands ? 0 : 100);
        };

        window.addEventListener('beforeunload', () => { active = false; }, { once: true });
        setTimeout(poll, 0);
    };

    bridge.invoke = (action, payload) => fetch('/__asyncrt/invoke', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify([action, String(Date.now()) + '-' + Math.random().toString(36).slice(2), payload === undefined ? null : payload])
    }).then((response) => {
        if (!response.ok)
            throw new Error('AsyncRT request failed with HTTP ' + response.status);

        return response.json();
    });

    bridge.__components = bridge.__components || {
        byID: new Map(),
        register(componentID, component) {
            this.byID.set(componentID, component);
        },
        unregister(componentID, component) {
            if (this.byID.get(componentID) === component)
                this.byID.delete(componentID);
        },
        update(componentID, state) {
            const component = this.byID.get(componentID);
            if (component && state && typeof state === 'object')
                component.setState(state);
        }
    };

    bridge.__dom = bridge.__dom || {
        exists(selector) {
            return document.querySelector(String(selector)) !== null;
        },
        readText(selector) {
            const el = document.querySelector(String(selector));
            return el ? el.textContent : null;
        },
        measure(selector) {
            const el = document.querySelector(String(selector));
            if (!el)
                return null;

            const r = el.getBoundingClientRect();
            return { x: r.x, y: r.y, width: r.width, height: r.height };
        },
        applyMutations(mutations) {
            const results = new Array(mutations.length);
            const elementsBySelector = new Map();

            const elementForSelector = (selector) => {
                selector = String(selector);
                if (!elementsBySelector.has(selector))
                    elementsBySelector.set(selector, document.querySelector(selector));

                return elementsBySelector.get(selector);
            };

            for (let index = 0; index < mutations.length; index++) {
                const mutation = mutations[index];
                const el = elementForSelector(mutation[1]);
                if (!el) {
                    results[index] = false;
                    continue;
                }

                const kind = mutation[0];
                const name = mutation[2];
                const value = mutation[3];

                switch (kind) {
                    case 0:
                        el.textContent = value;
                        results[index] = true;
                        break;
                    case 1:
                        el.innerHTML = value;
                        results[index] = true;
                        break;
                    case 2:
                        el.setAttribute(name, value);
                        results[index] = true;
                        break;
                    case 3:
                        el.removeAttribute(name);
                        results[index] = true;
                        break;
                    case 4:
                        el.style.setProperty(name, value);
                        results[index] = true;
                        break;
                    case 5:
                        el.classList.add(name);
                        results[index] = true;
                        break;
                    case 6:
                        el.classList.remove(name);
                        results[index] = true;
                        break;
                    case 7:
                        el.classList.toggle(name, Boolean(mutation[4]));
                        results[index] = true;
                        break;
                    default:
                        results[index] = false;
                        break;
                }
            }

            return results;
        }
    };

    window.AsyncRT = bridge;
    bridge.__startHTTPCommandPolling();
})();
