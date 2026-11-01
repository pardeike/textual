import SwiftUI
import Foundation
import Testing

@testable import Textual

@MainActor
struct TextBuilderImageTests {
  @Test func replacementStartsAtTheMeasuredContainerSize() {
    let environment = TextEnvironmentValues()
    let proposals = Proposals()
    var original = AttributedString("Map")
    original.textual.attachment = AnyAttachment(MapImage(description: "placeholder", proposals: proposals))
    let old = TextFragment<AttributedString>.TextBuilder(original, environment: environment)
    let size = CGSize(width: 320, height: 640)
    old.sizeChanged(size, environment: environment)

    var resolved = original
    resolved.textual.attachment = AnyAttachment(MapImage(description: "loaded", proposals: proposals))
    let replacement = TextFragment<AttributedString>.TextBuilder(
      resolved, environment: environment, containerSize: old.containerSize)

    #expect(replacement.containerSize == size)
    #expect(proposals.width == 320)
    _ = TextFragment<AttributedString>.TextBuilder(resolved, environment: environment)
    #expect(proposals.width == nil)
  }

  @Test func firstContentHasNoMeasuredContainer() {
    var content = AttributedString("Map")
    content.textual.attachment = AnyAttachment(MapImage(description: "first"))
    let builder = TextFragment<AttributedString>.TextBuilder(content, environment: .init())
    #expect(builder.containerSize == nil)
    builder.sizeChanged(CGSize(width: 200, height: 400), environment: .init())
    #expect(builder.containerSize == CGSize(width: 200, height: 400))
  }

  private final class Proposals: @unchecked Sendable, Hashable {
    private let lock = NSLock()
    private var value: CGFloat?
    var width: CGFloat? { lock.lock(); defer { lock.unlock() }; return value }
    func record(_ width: CGFloat?) { lock.lock(); defer { lock.unlock() }; value = width }
    static func == (lhs: Proposals, rhs: Proposals) -> Bool { lhs === rhs }
    func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
  }

  private struct MapImage: Textual.Attachment {
    let description: String
    var proposals = Proposals()
    var body: some View { Color.clear }
    func sizeThatFits(_ proposal: ProposedViewSize, in environment: TextEnvironmentValues) -> CGSize {
      proposals.record(proposal.width)
      let width = min(proposal.width ?? 1200, 1200)
      return CGSize(width: width, height: width * 1.5)
    }
  }
}
