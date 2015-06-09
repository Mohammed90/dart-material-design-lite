/**
 * Copyright (c) 2015, Michael Mitterer (office@mikemitterer.at),
 * IT-Consulting and Development Limited.
 *
 * All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

part of mdlcore;

/// Store strings for class names defined by this component that are used in Dart.
class _MdlComponentHandlerCssClasses {

    final String UPGRADING = "mdl-upgrading";

    final String UPGRADED = "mdl-upgraded";

    final String HTML_JS = "mdl-js";

    final String HTML_DART = "mdl-dart";

    final String DOWNGRADED = "mdl-downgraded";

    final String RIPPLE_EFFECT = "mdl-js-ripple-effect";

    const _MdlComponentHandlerCssClasses();
}

/**
 * A component handler interface using the revealing module design pattern.
 * More details on this pattern design here:
 * https://github.com/jasonmayes/mdl-component-design-pattern
 * (JS-Version: Jason Mayes.)
 *
 * @author Mike Mitterer
 */
class MdlComponentHandler {
    final Logger _logger = new Logger('mdlcore.ComponentHandler');

    final String _DATA_KEY = "data-upgraded";

    static const _MdlComponentHandlerCssClasses _cssClasses = const _MdlComponentHandlerCssClasses();

    final Map<String, MdlConfig> _registeredComponents = new HashMap<String, MdlConfig>();

    final List<di.Module> _modules = new List<di.Module>();

    /// If set to true it
    bool _enableVisualDebugging = false;

    /// The injector for this module.
    di.Injector _injector;

    /**
     * Registers a class for future use and attempts to upgrade existing DOM.
     * Sample:
     *      final ComponentHandler componenthandler = new ComponentHandler();
     *      componenthandler.register(new MdlConfig<MaterialButton>("mdl-button"));
     */
    void register(final MdlConfig config) {
        Validate.notNull(config);

        if(!_isValidClassName(config.classAsString)) {
            _logger.severe("(${config.classAsString}) is not a valid component for ${config.selector}");
            return;
        }

        if (!_isRegistered(config)) {
            _registeredComponents.putIfAbsent(config.classAsString, () => config);
        }
    }

    /**
     * Allows user to be alerted to any upgrades that are performed for a given
     * component type
     * [config] The class-config of the MDL component we wish
     * to hook into for any upgrades performed.
     * The [callback]-function to call upon an upgrade. This
     * function should expect 1 parameter - the HTMLElement which got upgraded.
     */
    void registerUpgradedCallback(final MdlConfig config,final MdlCallback callback) {

        if(_isValidClassName(config.classAsString) && _isRegistered(config)) {
            _registeredComponents[config.classAsString].callbacks.add(callback);
        }
    }

    @deprecated
    Future upgradeAllRegistered() => run();

    /**
     * Upgrades all registered components found in the current DOM. This
     * should be called in your main-function.
     * At the beginning of the upgrade-process it adds the css-classes
     * mdl-js, mdl-dart and mdl-upgrading to the <html>-element.
     * If all components are ready it removes mdl-upgrading.
     *
     * Sample:
     *        main() {
     *        registerMdl();
     *
     *        componentFactory().run().then( (_) {
     *
     *              });
     *        }
     */
    Future<di.Injector> run( { final enableVisualDebugging: false } ) {
        final dom.Element body = dom.querySelector("body");

        _enableVisualDebugging = enableVisualDebugging;
        //_modules.add(new di.Module()..bind(DomRenderer));

        _injector = _createInjector();

        return upgradeElement(body);
    }

    /// Upgrades all children for {element} and returns the current Injector
    Future<di.Injector> upgradeElement(final dom.HtmlElement element) {
        Validate.notNull(_injector,"Injector must not be null - did you call run?");
        Validate.notNull(element,"Component must not be null!");

        dom.querySelector("html")
            ..classes.add(_cssClasses.HTML_JS)
            ..classes.add(_cssClasses.HTML_DART)
            ..classes.remove(_cssClasses.UPGRADED);

        final Future<di.Injector> future = new Future<di.Injector>( () {

            element.classes.add(_cssClasses.UPGRADING);

            _configs.forEach((final MdlConfig config) {
                _upgradeDom(element,config);
                _logger.fine("${config.selector} upgraded with ${config.classAsString}...");
            });

            element.classes.remove(_cssClasses.UPGRADING);
            element.classes.add(_cssClasses.UPGRADED);

            dom.querySelector("body").classes.remove(_cssClasses.UPGRADING);
            dom.querySelector("html").classes.add(_cssClasses.UPGRADED);
            _logger.info("All components are upgraded...");

            return _injector;
        });

        return future;
    }

    MdlComponentHandler addModule(final di.Module module) {
        if(_modules.indexOf(module) == -1) {
            _modules.add(module);
        }
        return this;
    }

    /// Returns the injector for this module.
    di.Injector get injector => _injector;

    /// downgrade() will be called for the given Component and it's children
    Future downgradeElement(final dom.HtmlElement element) {
        Validate.notNull(element,"Element to downgrade must not be null!");

        final Completer completer = new Completer();

        new Future(() {
            if(element is dom.HtmlElement) {

            final List<dom.Element> children = element.querySelectorAll('[class*="mdl-"]');

            // Children first
            children.forEach((final dom.Element element) => _deconstructComponent(element));

            _deconstructComponent(element);
            }

            completer.complete();
        });

        return completer.future;
    }

    //- private -----------------------------------------------------------------------------------

    bool _isRegistered(final MdlConfig config) => _registeredComponents.containsKey(config.classAsString);

    bool _isValidClassName(final String classname) => (classname != "dynamic");

    /// The component with the highest priority comes last
    List<MdlConfig> get _configs {
        final List<MdlConfig> configs = new List<MdlConfig>.from(_registeredComponents.values);

        configs.sort((final MdlConfig a, final MdlConfig b) {
            return a.priority.compareTo(b.priority);
        });

        return configs;
    }

    /**
     * Searches existing DOM for elements of our component type and upgrades them
     * if they have not already been upgraded!
     * {queryBaseElement} defines where the querySelector starts to search - can be any element.
     * upgradeAllRegistered uses "body" as {queryBaseElement}
     */
    void _upgradeDom(final dom.Element queryBaseElement, final MdlConfig config) {
        Validate.notNull(queryBaseElement);
        Validate.notNull(config);

//        final List<Future> futureUpgrade = new List<Future>();
//        final Future future = new Future(() {

        /// Check if {config.selector} is either the class-name or the tag name of {baseElement}
        /// If so - upgrade
        void _upgradeBaseElementIfSelectorFits(final dom.Element baseElement) {
            if(config.isSelectorAClassName && queryBaseElement.classes.contains(config.selector.replaceFirst(".",""))) {
                _upgradeElement(queryBaseElement, config);
            } else if(!config.isSelectorAClassName && queryBaseElement.tagName == config.selector) {
                _upgradeElement(queryBaseElement, config);
            }
        }

        final dom.ElementList<dom.HtmlElement> elements = queryBaseElement.querySelectorAll(config.selector);
        _upgradeBaseElementIfSelectorFits(queryBaseElement);
        elements.forEach((final dom.HtmlElement element) {

            _upgradeElement(element, config);

            // futureUpgrade.add(_upgradeElement(element, config));
        });

//        });
//        futureUpgrade.add(future);
//        Future.wait(futureUpgrade);
    }

    /**
     * Upgrades a specific element rather than all in the DOM.
     * [element] is the element we wish to upgrade.
     * [config] the Dart-Class/Css-Class configuration of the class we want to upgrade
     * the element to.
     */
    void _upgradeElement(final dom.HtmlElement element, final MdlConfig config) {
        Validate.notNull(element);
        Validate.notNull(config);

        if (!element.attributes.containsKey(_DATA_KEY) || element.attributes[_DATA_KEY].contains(config.classAsString) == false) {

            void _markAsUpgraded() {
                final List<String> registeredClasses = element.attributes.containsKey(_DATA_KEY)
                ? element.attributes[_DATA_KEY].split(",") : new List<String>();

                registeredClasses.add(config.classAsString);
                element.attributes[_DATA_KEY] = registeredClasses.join(",");
            }

            try {
                final MdlComponent component = config.newComponent(element,_injector);

                component.visualDebugging = _enableVisualDebugging;
                config.callbacks.forEach((final MdlCallback callback) => callback(element));

                _markAsUpgraded();
                _logger.fine("${config.classAsString} -> ${component}");

                // Makes it possible to query for the main element in this component.
                var jsElement = new JsObject.fromBrowserObject(component.hub);

                if(config.isWidget) {
                    jsElement[MDL_WIDGET_PROPERTY] = component;

                } else {
                    jsElement[MDL_RIPPLE_PROPERTY] = component;
                }

            }
            catch (exception, stacktrace) {
                _logger.severe("Registration for: ${config.selector} not possible. Check if ${config.classAsString} is correctly imported");
                _logger.severe(exception, stacktrace);
            }
        }
    }

    /**
     * Creates an injector function that can be used for retrieving services as well as for
     * dependency injection.
     */
    di.Injector _createInjector() {
        return new di.ModuleInjector(_modules);
    }

    /// Downgrades the given {element}
    void _deconstructComponent(final dom.HtmlElement element) {
        try {
            // Also remove the Widget-Property
            var jsElement = new JsObject.fromBrowserObject(element);

            MdlComponent component;
            if(jsElement.hasProperty(MDL_RIPPLE_PROPERTY)) {

                component = jsElement[MDL_RIPPLE_PROPERTY] as MdlComponent;

                component.downgrade();

                jsElement.deleteProperty(MDL_RIPPLE_PROPERTY);
            }

            if(jsElement.hasProperty(MDL_WIDGET_PROPERTY)) {
                component = jsElement[MDL_WIDGET_PROPERTY] as MdlComponent;

                component.downgrade();

                jsElement.deleteProperty(MDL_WIDGET_PROPERTY);
            }

            // doesn't mater if it is a widget or a ripple...
            if(component != null) {
                component.attributes.remove(_DATA_KEY);
                component.classes.add(_cssClasses.DOWNGRADED);
            }

        } on String catch (e) {
            _logger.severe(e);
        }
    }
}

