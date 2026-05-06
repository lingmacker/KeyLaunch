import SwiftUI

struct SettingsView: View {
    @Bindable var model: KeyLaunchModel

    var body: some View {
        VStack(spacing: 0) {
            header
            content
                .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("快捷启动")
                    .font(.title2.weight(.semibold))
                Text("设置快捷键，一键打开常用 App")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                model.reloadApps()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("刷新 App 列表")
            .accessibilityLabel("刷新 App 列表")

            Button {
                model.addRow()
            } label: {
                Image(systemName: "plus")
            }
            .help("新增快捷键配置")
            .accessibilityLabel("新增快捷键配置")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 12) {
            if model.config.rows.isEmpty {
                ContentUnavailableView(
                    "暂无快捷键配置",
                    systemImage: "keyboard",
                    description: Text("点击右上角加号添加一条快捷键启动规则。")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: SettingsLayout.cardCornerRadius))
            } else {
                VStack(spacing: 0) {
                    tableHeader
                    Divider()
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(model.config.rows) { row in
                                ShortcutRowView(row: row, apps: model.installedApps, model: model)
                                Divider()
                            }
                        }
                    }
                }
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: SettingsLayout.cardCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: SettingsLayout.cardCornerRadius)
                        .stroke(.separator.opacity(0.45))
                )
            }

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var tableHeader: some View {
        Grid(horizontalSpacing: SettingsLayout.rowHorizontalSpacing, verticalSpacing: 0) {
            GridRow {
                Text("快捷键")
                    .frame(width: SettingsLayout.shortcutColumnWidth, alignment: .leading)
                    .padding(.leading, 15)
                Text("打开的 App")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                Text("操作")
                    .frame(width: SettingsLayout.actionColumnWidth, alignment: .center)
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
