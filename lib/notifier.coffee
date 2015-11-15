{ CompositeDisposable, Emitter } = require 'atom'

module.exports =
class AtoumNotifier extends Emitter
    constructor: (@runner, @parser) ->
        super()

        @subscriptions = new CompositeDisposable

        count = 0
        failure = 0
        skip = 0
        voidNumber = 0
        @subscriptions.add @parser.on 'plan', ->
            count = 0
            failure = 0
            skip = 0
            voidNumber = 0

        @subscriptions.add @parser.on 'test', (test) ->
            count += 1
            failure += 1 if test.status is 'not ok'
            skip += 1 if test.status is 'skip'
            voidNumber += 1 if test.status is 'void'

        @subscriptions.add @runner.on 'stop', (code) =>
            return unless @enabled

            if code is 0 and skip is 0 and voidNumber is 0
                notification = atom.notifications.addSuccess 'Tests passed',
                    detail: count.toString() + ' test(s) passed!'
                    dismissable: true
                    icon: 'check'

            if code is 0 and (skip isnt 0 or voidNumber isnt 0)
                notification = atom.notifications.addWarning 'Tests passed',
                    detail: count + ' test(s) passed with ' + voidNumber + ' void test(s) and ' + skip + ' skipped test(s).'
                    dismissable: true
                    icon: 'primitive-dot'

            if code is 255
                notification = atom.notifications.addError 'atoum error',
                    detail: 'There was an error when running tests!'
                    dismissable: true
                    icon: 'flame'
            else if code > 0
                notification = atom.notifications.addError 'Tests failed',
                    detail: failure.toString() + ' of ' + count.toString() + ' test(s) failed!'
                    dismissable: true
                    icon: 'flame'

            if code > 0 or skip isnt 0 or voidNumber isnt 0
                @subscriptions.add notification.onDidDismiss => @emit 'dismiss', notification

        @enable()

    destroy: ->
        @subscriptions.dispose()

    enable: ->
        @enabled = true

    disable: ->
        @enabled = false