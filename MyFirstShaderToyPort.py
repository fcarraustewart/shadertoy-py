from glapp.PyOGLApp import *
from glapp.Utils import *
from glapp.Mesh import *

class MyFirstShaderToyPort(PyOGLApp):
    def __init__(self):
        super().__init__(850,100,1000,1000)
        self.screen_plane = None

    def initialise(self):
        self.program_id = create_program(open("shaders/vert.vs").read(), open("shaders/frag.vs").read())
        self.screen_plane = Mesh(self.program_id)

    def display(self):
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        glUseProgram(self.program_id)
        res_id = glGetUniformLocation(self.program_id, "iResolution")
        glUniform2f(res_id, self.screen_width, self.screen_height)
        self.screen_plane.draw()


MyFirstShaderToyPort().mainloop()