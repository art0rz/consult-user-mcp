#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QJsonDocument>
#include <QUrl>
#include <QJsonObject>
#include <QTextStream>
#include <QVersionNumber>

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
