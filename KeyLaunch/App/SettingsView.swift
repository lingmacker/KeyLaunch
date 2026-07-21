import SwiftUI

struct SettingsView: View {
    @Bindable var model: KeyLaunchModel

    private var canAddRule: Bool {
        !model.installedApps.isEmpty && model.config.rows.count < shortcutNames.count
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
                .padding(.horizontal, SettingsLayout.contentPadding)
                .padding(.top, 16)
                .padding(.bottom, 14)
        }
        .frame(
            minWidth: 640,
            maxWidth: .infinity,
            minHeight: 440,
            maxHeight: .infinity,
            alignment: .top
        )
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "command")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .background(
                    Color.accentColor.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 9)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("快捷启动")
                    .font(.title2.weight(.semibold))
                Text("用全局快捷键立即打开常用 App")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 20)

            Button {
                model.reloadApps()
            } label: {
                HStack(spacing: 6) {
                    if model.isReloading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(model.isReloading ? "正在刷新…" : "刷新 App")
                }
            }
            .buttonStyle(.bordered)
            .disabled(model.isReloading)
            .help("重新扫描“应用程序”文件夹")

            Button {
                model.addRow()
            } label: {
                Label("添加快捷键", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAddRule)
            .keyboardShortcut("n", modifiers: .command)
            .help(addRuleHelp)
        }
        .padding(.horizontal, SettingsLayout.contentPadding)
        .padding(.vertical, 14)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let errorMessage = model.errorMessage {
                errorBanner(errorMessage)
            }

            if model.config.rows.isEmpty {
                emptyState
            } else {
                rulesSection
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("启动规则")
                    .font(.headline)

                Spacer()

                Text("\(model.config.rows.count) / \(shortcutNames.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("已配置 \(model.config.rows.count) 条，最多 \(shortcutNames.count) 条")
            }

            VStack(spacing: 0) {
                tableHeader
                Divider()
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(model.config.rows) { row in
                            ShortcutRowView(row: row, apps: model.installedApps, model: model)

                            if row.id != model.config.rows.last?.id {
                                Divider()
                                    .padding(.leading, 14)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Color(nsColor: .controlBackgroundColor),
                in: RoundedRectangle(cornerRadius: SettingsLayout.panelCornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: SettingsLayout.panelCornerRadius)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.55))
            }
            .clipShape(RoundedRectangle(cornerRadius: SettingsLayout.panelCornerRadius))

            Text("更改会自动保存。录制后，快捷键可在任何 App 中使用。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "keyboard")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 56, height: 56)
                .background(
                    Color.accentColor.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .accessibilityHidden(true)

            VStack(spacing: 5) {
                Text("添加第一个快捷键")
                    .font(.headline)
                Text("录制一个全局快捷键，再选择需要打开的 App。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                model.addRow()
            } label: {
                Label("添加快捷键", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAddRule)
            .help(addRuleHelp)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
        .background(
            Color(nsColor: .controlBackgroundColor),
            in: RoundedRectangle(cornerRadius: SettingsLayout.panelCornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: SettingsLayout.panelCornerRadius)
                .stroke(Color(nsColor: .separatorColor).opacity(0.55))
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .accessibilityHidden(true)

            Text(message)
                .font(.callout)
                .textSelection(.enabled)

            Spacer()

            Button {
                model.dismissError()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
            .help("关闭")
            .accessibilityLabel("关闭错误提示")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            Color.red.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.red.opacity(0.2))
        }
    }

    private var tableHeader: some View {
        Grid(horizontalSpacing: SettingsLayout.rowHorizontalSpacing, verticalSpacing: 0) {
            GridRow {
                Text("快捷键")
                    .frame(width: SettingsLayout.shortcutColumnWidth, alignment: .leading)
                Text("打开的 App")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Color.clear
                    .frame(width: SettingsLayout.actionColumnWidth, height: 1)
                    .accessibilityHidden(true)
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var addRuleHelp: String {
        if model.installedApps.isEmpty {
            return "没有找到可打开的 App"
        }
        if model.config.rows.count >= shortcutNames.count {
            return "最多支持 \(shortcutNames.count) 个快捷键"
        }
        return "新增快捷键配置（⌘N）"
    }
}
