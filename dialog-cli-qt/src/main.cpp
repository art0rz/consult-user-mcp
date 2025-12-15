#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QJsonDocument>
#include <QUrl>
#include <QJsonObject>
#include <QTextStream>
#include <QVersionNumber>
#include <QProcess>

class ResultEmitter : public QObject {
    Q_OBJECT
public:
    Q_INVOKABLE void emitJson(const QString &json) {
        QTextStream(stdout) << json << "\n";
        QCoreApplication::quit();
    }
};

static QJsonObject parseJsonArg(const QString &arg) {
    const auto doc = QJsonDocument::fromJson(arg.toUtf8());
    if (!doc.isObject()) {
        return QJsonObject{};
    }
    return doc.object();
}

static void writeJson(const QJsonObject &obj) {
    QTextStream(stdout) << QString::fromUtf8(QJsonDocument(obj).toJson(QJsonDocument::Compact)) << "\n";
}

static bool runNotify(const QJsonObject &payload) {
    const QString message = payload.value("message").toString();
    if (message.isEmpty()) return false;

    const QString title = payload.value("title").toString(QStringLiteral("Notice"));
    const QString subtitle = payload.value("subtitle").toString();
    const QString body = subtitle.isEmpty() ? message : (subtitle + "\n" + message);

    const int code = QProcess::execute(QStringLiteral("notify-send"), { title, body });
    return code == 0;
}

static bool runTts(const QJsonObject &payload) {
    const QString text = payload.value("text").toString();
    if (text.isEmpty()) return false;

    const QString voice = payload.value("voice").toString();
    const int rate = payload.value("rate").toInt(200);

    QStringList spdArgs;
    if (!voice.isEmpty()) spdArgs << "-v" << voice;
    spdArgs << "-r" << QString::number(rate);
    spdArgs << text;

    int code = QProcess::execute(QStringLiteral("spd-say"), spdArgs);
    if (code == 0) return true;

    QStringList espeakArgs;
    if (!voice.isEmpty()) espeakArgs << "-v" << voice;
    espeakArgs << "-s" << QString::number(rate);
    espeakArgs << text;

    code = QProcess::execute(QStringLiteral("espeak"), espeakArgs);
    return code == 0;
}

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QCoreApplication::setApplicationName("consult-user-dialog");
    QCoreApplication::setApplicationVersion("1.0.0");

    if (argc < 2) {
        QTextStream(stderr) << "Usage: consult-user-dialog <command> [json]\n";
        return 1;
    }

    const QString command = QString::fromUtf8(argv[1]);
    const QString payloadArg = argc >= 3 ? QString::fromUtf8(argv[2]) : QStringLiteral("{}");
    const QJsonObject payload = parseJsonArg(payloadArg);

    // Pulse is headless, return immediately
    if (command == QLatin1String("pulse")) {
        QTextStream(stdout) << "{\"success\":true}" << "\n";
        return 0;
    }

    // Non-interactive commands handled in-process
    if (command == QLatin1String("notify")) {
        const bool ok = runNotify(payload);
        writeJson(QJsonObject{{"success", ok}});
        return ok ? 0 : 1;
    }

    if (command == QLatin1String("tts")) {
        const bool ok = runTts(payload);
        writeJson(QJsonObject{{"success", ok}});
        return ok ? 0 : 1;
    }

    QQmlApplicationEngine engine;
    ResultEmitter emitter;

    engine.rootContext()->setContextProperty("cliCommand", command);
    engine.rootContext()->setContextProperty("cliPayload", payload.toVariantMap());
    engine.rootContext()->setContextProperty("resultEmitter", &emitter);
    engine.rootContext()->setContextProperty("cliVersion", QCoreApplication::applicationVersion());

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated, &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        QTextStream(stderr) << "Failed to load QML." << "\n";
        return 1;
    }

    return app.exec();
}

#include "main.moc"
