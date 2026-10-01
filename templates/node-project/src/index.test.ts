import { describe, it, expect } from "vitest";
import { greet, main } from "../index";

describe("greet", () => {
  it("returns default greeting", () => {
    expect(greet()).toBe("Hello, World!");
  });

  it("returns personalized greeting", () => {
    expect(greet("Alice")).toBe("Hello, Alice!");
  });
});

describe("main", () => {
  it("exits with 0 on default", () => {
    expect(main([])).toBe(0);
  });

  it("exits with 0 on help", () => {
    expect(main(["--help"])).toBe(0);
  });

  it("exits with 0 on version", () => {
    expect(main(["--version"])).toBe(0);
  });
});