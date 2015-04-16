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

part of mdlcomponents;

/// Store strings for class names defined by this component that are used in
/// Dart. This allows us to simply change it in one place should we
/// decide to modify at a later date.
class _MaterialProgressCssClasses {

    final String INDETERMINATE_CLASS = 'mdl-progress__indeterminate';
    final String IS_UPGRADED = 'is-upgraded';

    const _MaterialProgressCssClasses();
}

/// Store constants in one place so they can be updated easily.
class _MaterialProgressConstant {
    const _MaterialProgressConstant();
}

/// registration-Helper
void registerMaterialProgress() => componenthandler.register(new MdlWidgetConfig<MaterialProgress>(
    "mdl-js-progress", (final html.HtmlElement element) => new MaterialProgress.fromElement(element)));

class MaterialProgress extends MdlComponent {
    final Logger _logger = new Logger('mdlcomponents.MaterialProgress');

    static const _MaterialProgressConstant _constant = const _MaterialProgressConstant();
    static const _MaterialProgressCssClasses _cssClasses = const _MaterialProgressCssClasses();

    html.DivElement _progressbar;
    html.DivElement _bufferbar;
    html.DivElement _auxbar;

    factory MaterialProgress(final html.HtmlElement element) => mdlComponent(element) as MaterialProgress;

    //    factory MaterialProgress() =>  new html.Element.tag('mdl-progress');
//
//    MaterialProgress.created() : super.created() {
//        _logger.info("created");
//        classes.add("mdl-js-progress");
//        element = this;
//        _init();
//    }

    MaterialProgress.fromElement(final html.HtmlElement element) : super(element) {
        _init();
    }

//    init(final html.HtmlElement element) {
//        this.element = element;
//        _init();
//    }

    static MaterialProgress widget(final html.HtmlElement element) => mdlComponent(element) as MaterialProgress;

    /// MaterialProgress.prototype.setProgress = function(p) {
    void set progress(final int width) {

        if (element.classes.contains(_cssClasses.INDETERMINATE_CLASS)) {
            return;
        }

        _progressbar.style.width = "${width}%";
    }

    int get progress {
        if (element.classes.contains(_cssClasses.INDETERMINATE_CLASS)) {
            return 0;
        }
        return int.parse(_progressbar.style.width.replaceFirst("%",""));
    }

    /// MaterialProgress.prototype.setBuffer = function(p) {
    void set buffer(final int width) {
        _bufferbar.style.width = "${width}%";
        _auxbar.style.width = "${100 - width}%";
    }

    //- private -----------------------------------------------------------------------------------

    void _init() {
        _logger.info("MaterialProgress - init");

        if (element != null) {

            _progressbar = new html.DivElement();
            _progressbar.classes.addAll([ 'progressbar', 'bar', 'bar1']);
            element.append(_progressbar);

            _bufferbar = new html.DivElement();
            _bufferbar.classes.addAll([ 'bufferbar', 'bar', 'bar2']);
            element.append(_bufferbar);

            _auxbar = new html.DivElement();
            _auxbar.classes.addAll([ 'auxbar', 'bar', 'bar3']);
            element.append(_auxbar);

            _progressbar.style.width = '0%';
            _bufferbar.style.width = '100%';
            _auxbar.style.width = '0%';

            element.classes.add(_cssClasses.IS_UPGRADED);
        }
    }
}

