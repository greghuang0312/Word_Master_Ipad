import SwiftUI

struct AddWordView: View {
    @StateObject private var viewModel: AddWordViewModel

    init(context: AppContext) {
        _viewModel = StateObject(wrappedValue: AddWordViewModel(context: context))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("输入中文词义")
                    .font(.headline)

                TextField("例如：苹果", text: $viewModel.zhText)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task { await viewModel.queryCandidates() }
                } label: {
                    if viewModel.loading {
                        ProgressView()
                    } else {
                        Text("查询英文候选")
                    }
                }
                .buttonStyle(.borderedProminent)

                if !viewModel.candidates.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("候选英文（单选）")
                            .font(.headline)
                        ForEach(viewModel.candidates, id: \.self) { candidate in
                            HStack {
                                Image(systemName: viewModel.selectedCandidate == candidate ? "largecircle.fill.circle" : "circle")
                                Text(candidate)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { viewModel.selectedCandidate = candidate }
                            .padding(.vertical, 4)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("手写英文（可选，优先于候选）")
                        .font(.headline)
                    TextField("例如：apple", text: $viewModel.manualEnglish)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                HStack {
                    Button("保存词条") {
                        Task { await viewModel.save() }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("清空") {
                        viewModel.resetInput()
                    }
                    .buttonStyle(.bordered)
                }

                if !viewModel.notice.isEmpty {
                    Text(viewModel.notice)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("添加")
    }
}

