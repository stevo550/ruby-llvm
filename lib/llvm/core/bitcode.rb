module LLVM
  module C
    attach_function :LLVMParseBitcode, [:pointer, :buffer_out, :buffer_out], :int
    attach_function :LLVMParseBitcodeInContext, [:pointer, :pointer, :buffer_out, :buffer_out], :int
    attach_function :LLVMWriteBitcodeToFile, [:pointer, :string], :int
    attach_function :LLVMWriteBitcodeToFD, [:pointer, :int, :int, :int], :int
  end

  class Module
    def self.parse_bitcode(memory_buffer)
      mod_ref = FFI::Buffer.new(:pointer)
      msg_ref = FFI::Buffer.new(:pointer)
      status = C.LLVMParseBitcode(memory_buffer, mod_ref, msg_ref)
      raise msg_ref.get_pointer(0).get_string(0) if status != 0
      from_ptr(mod_ref.get_pointer(0))
    end

    # Write bitcode to the given path, IO object or file descriptor
    # @param [String, IO, Fixnum] Pathname, IO object or file descriptor
    # @return [true, false] Success
    def write_bitcode(path_or_io)
      status = if path_or_io.respond_to?(:fileno)
                 C.LLVMWriteBitcodeToFD(self, path_or_io.fileno, 0, 1)
               elsif path.kind_of?(Integer)
                 C.LLVMWriteBitcodeToFD(self, path_or_io, 0, 1)
               else
                 C.LLVMWriteBitcodeToFile(self, path_or_io.to_str)
               end
      return status == 0
    end
  end

  class MemoryBuffer
    private_class_method :new

    # @private
    def initialize(ptr)
      @ptr = ptr
    end

    # @private
    def to_ptr
      @ptr
    end

    # Read the contents of a file into a memory buffer
    # @param [String] path
    # @return [LLVM::MemoryBuffer]
    def self.from_file(path)
      buf_ref = FFI::Buffer.new(:pointer)
      msg_ref = FFI::Buffer.new(:pointer)
      status = C.LLVMCreateMemoryBufferWithContentsOfFile(path, buf_ref, msg_ref)
      raise msg_ref.get_pointer(0).get_string(0) if status != 0
      new(buf_ref.get_pointer(0))
    end

    # Read STDIN into a memory buffer
    # @return [LLVM::MemoryBuffer]
    def self.from_stdin
      buf_ref = FFI::Buffer.new(:pointer)
      msg_ref = FFI::Buffer.new(:pointer)
      status = C.LLVMCreateMemoryBufferWithSTDIN(buf_ref, msg_ref)
      raise msg_ref.get_pointer(0).get_string(0) if status != 0
      new(buf_ref.get_pointer(0))
    end

    def dispose
      C.LLVMDisposeMemoryBuffer(@ptr)
    end
  end
end