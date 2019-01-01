import matlab.engine
import itertools

eng = None

class Node():
    '''
    A simple node class meant to create n-ary trees used to represent SLSF
    hierarchies.
    '''

    def __init__(self, state):
        self.name = eng.get(state,'Name')
        self.decomp = decomp(state)
        self.children = []
        self.state = state

    def addChild(self, c):
        self.children.append(c)


class SuperMode():
    def __init__(self, submodes):
        self.submodes = submodes
        name = ""
        for m in submodes:
            name = name + eng.get(m,'Name') + "__"
        self.name = name[:-2]
        self.flow = ""
        self.deriveCombinedFlow()
        self.matlabObj = None #must be explicitly placed on a chart first

    @property
    def submodeNames(self):
        return [eng.get(s,'Name') for s in self.submodes]

    def __repr__(self):
        return self.name

    def deriveCombinedFlow(self):
        flows = list(map(extractFlow,self.submodes))
        for flow in flows:
            self.flow = self.flow + flow + '\n'

    def attachToChart(self, chart):
        self.matlabObj = eng.Stateflow.State(chart)
        eng.set(self.matlabObj,'Name',self.name, nargout=0)
        eng.set(self.matlabObj,'LabelString',self.name + ":" + "\n" + self.flow, nargout=0)


def extractFlow(mode):
    raw = eng.get(mode,'LabelString')

    if not ':' in raw:
        return ""
    else:
        return raw.split(":")[-1]

def buildTree(state,allChildren):
    n = Node(state)
    for child in allChildren:
        if eng.get(state,"Name") == eng.get(eng.getParent(child[0]),"Name"):
            n.addChild(buildTree(child[0], allChildren))
    return n

def decomp(state):
   return "AND" if eng.get(state,"Decomposition") == "PARALLEL_AND" else "OR"

def enumerateSuperNodes(tree):
    '''Given a tree representing an SLSF mode hierarchy, create "supernodes" that
    consist of all valid traversals of the AND-OR tree. If a node has a
    decomposition of AND, we create a supermode consisting of all combinations
    of its subtrees' supernodes (as well as its mode). If it is an OR node, we
    combine the node's state exclusively with its subtrees, instead of
    combining them.

    '''
    if tree.children == []:
        return [[tree.state]]

    if tree.decomp == 'AND':
        superNodes = [[tree.state]]
        for child in tree.children:
            #combine each child in sequence, building up all combinations of
            #all supernodes as we go
            superNodes = [x + y
                          for x in superNodes
                          for y in enumerateSuperNodes(child)]
    else:
        superNodes = []
        for child in tree.children:
            #combine the state with each of the possibly many child supernodes
            #exclusively
            superNodes = superNodes + [[tree.state] + s
                                       for s in enumerateSuperNodes(child)]
    return superNodes

def run():

    #connect MATLAB engine and load test chart and all child modes
    global eng
    eng = matlab.engine.connect_matlab(matlab.engine.find_matlab()[0])
    chart = eng.find(eng.sfroot(),'-isa','Stateflow.Chart',
                     '-and', 'Path', 'thermostat/Chart')
    allChildren = eng.find(chart,'-isa','Stateflow.State')

    #construct superModes from the SLSF hierarchy tree
    t = buildTree(chart,allChildren)
    n = enumerateSuperNodes(t)
    n = list(map(lambda l: l[1:],n))
    superModes = list(map(SuperMode,n))

    #make a new flattened chart and add supermodes to it
    eng.sfnew('flattened')
    flatChart = eng.find(eng.sfroot(),'-isa','Stateflow.Chart',
                         '-and','Path','flattened/Chart')
    for m in superModes:
        m.attachToChart(flatChart)

    allTransitions = [t[0] for t in eng.find(chart,'-isa','Stateflow.Transition')]

    #place a single initial transition on the mode that is the superposition of
    #all the hierarchical modes with initial transitions
    initTransitions = [t for t in allTransitions if eng.get(t,'Source').size == (0,0)]
    initModes = [eng.get(t,'Destination') for t in initTransitions]
    initNames = [eng.get(m,'Name') for m in initModes]
    initSuperMode = [m for m in superModes if set(initNames) <= set(m.submodeNames)][0]

    guards = [eng.get(t,'LabelString').strip().strip("{}") for t in initTransitions]
    newGuard = "{" + ";\n".join(guards) + "}"
    t = eng.Stateflow.Transition(flatChart)
    eng.set(t,'LabelString',newGuard,'Destination',initSuperMode.matlabObj, nargout=0)

    allPairs = itertools.permutations(superModes,2)
    newTs = []
    for i, (m1,m2) in enumerate(allPairs):
        # find all transitions that are valid for m1,m2, i.e. all transitions
        # whose source is s1 and dest is s2, where s1 in m1.submodes and s2 in
        # m2.submodes
        m1Modes = [eng.get(m,'Name') for m in m1.submodes]
        m2Modes = [eng.get(m,'Name') for m in m2.submodes]

        relevantTransitions = [t for t in allTransitions
                               if (eng.get(eng.get(t,'Source'),'Name') in m1Modes and
                                 eng.get(eng.get(t,'Destination'), 'Name') in m2Modes)]

        if relevantTransitions == []:
            import pdb; pdb.set_trace()
            continue

        #construct one transition that combines the guards of all the transitions
        guards = [eng.get(t,'LabelString').strip("[]") for t in relevantTransitions]
        newGuard = " && ".join(guards)

        print(i)
        #add that transition between m1 and m2
        t = eng.Stateflow.Transition(flatChart)
        eng.set(t,'LabelString',newGuard,
                'Source',m1.matlabObj,'Destination',m2.matlabObj,nargout=0)

    eng.quit()
