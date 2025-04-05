import SwiftUI
import AVKit

struct GalleryView: View {
    @ObservedObject var recorder: RecordingManager
    @State private var selectedRecording: RecordingMetadata?
    @State private var showPreview = false
    @State private var editMode: EditMode = .inactive
    @State private var selection = Set<UUID>()

    var body: some View {
        NavigationView {
            List(selection: $selection) {
                ForEach(recorder.recordings.reversed()) { recording in
                    Button {
                        if editMode == .active {
                            toggleSelection(for: recording)
                        } else {
                            selectedRecording = recording
                        }
                    } label: {
                        HStack(spacing: 12) {
                            if let thumbnail = recording.thumbnail {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 40)
                                    .clipped()
                                    .cornerRadius(6)
                            } else {
                                Image(systemName: "film")
                                    .resizable()
                                    .frame(width: 40, height: 30)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(.gray.opacity(0.4))
                                    .cornerRadius(8)
                            }

                            VStack(alignment: .leading) {
                                Text(recording.displayName)
                                    .font(.headline)
                                Text(recording.formattedDetails)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("⏱ \(recording.durationFormatted)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .tag(recording.id)
                }
                .onDelete(perform: delete)
            }
            .environment(\.editMode, $editMode)
            .navigationTitle("Recordings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if editMode == .active {
                        Button("Delete", role: .destructive) {
                            deleteSelected()
                        }
                        .disabled(selection.isEmpty)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editMode == .active ? "Cancel" : "Select") {
                        withAnimation {
                            editMode = editMode == .active ? .inactive : .active
                            if editMode == .inactive {
                                selection.removeAll()
                            }
                        }
                    }
                }
            }
            .sheet(item: $selectedRecording) { recording in
                RecordingPreviewView(recording: recording)
            }
        }
    }

    private func toggleSelection(for recording: RecordingMetadata) {
        if selection.contains(recording.id) {
            selection.remove(recording.id)
        } else {
            selection.insert(recording.id)
        }
    }

    // Single item delete
    private func delete(at offsets: IndexSet) {
        let reversedArray = Array(recorder.recordings.reversed())
        let toDelete = offsets.map { reversedArray[$0] }
        for recording in toDelete {
            recorder.deleteRecording(recording)
        }
    }


    // Multiple item delete
    private func deleteSelected() {
        for id in selection {
            if let recording = recorder.recordings.first(where: { $0.id == id }) {
                recorder.deleteRecording(recording)
            }
        }
        selection.removeAll()
        editMode = .inactive
    }
}
