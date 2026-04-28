from typing import List, Dict, Tuple
from app.models.schemas import RoadmapGenerationResponse, SkillNode, StudyRoadmapResponse
from collections import deque, defaultdict
import uuid

def generate_study_roadmap(document_id: uuid.UUID, llm_response: RoadmapGenerationResponse) -> StudyRoadmapResponse:
    """
    Takes the LLM's raw RoadmapGenerationResponse and builds a valid DAG.
    Performs Kahn's Algorithm for Topological Sorting to determine the study order.
    Gracefully handles and breaks cycles if the LLM hallucinates them.
    """
    # 1. Build Adjacency List and In-Degree Map
    # graph[u] = list of v, meaning u is a prerequisite for v (u -> v)
    graph: Dict[str, List[str]] = defaultdict(list)
    in_degree: Dict[str, int] = defaultdict(int)
    
    # Quick lookup for SkillNode
    skill_map: Dict[str, SkillNode] = {skill.skill_name: skill for skill in llm_response.skills}
    
    # Initialize in-degree to 0 for all known skills
    for skill in llm_response.skills:
        if skill.skill_name not in in_degree:
            in_degree[skill.skill_name] = 0
            
    # Populate edges based on prerequisites
    for skill in llm_response.skills:
        for prereq in skill.prerequisites:
            # Only add edges if the prereq actually exists in our skill list
            if prereq in skill_map:
                graph[prereq].append(skill.skill_name)
                in_degree[skill.skill_name] += 1
                
    # 2. Perform Kahn's Algorithm (Topological Sort)
    ordered_skills_names: List[str] = []
    queue = deque([node for node, deg in in_degree.items() if deg == 0])
    
    while queue:
        current = queue.popleft()
        ordered_skills_names.append(current)
        
        for neighbor in graph[current]:
            in_degree[neighbor] -= 1
            if in_degree[neighbor] == 0:
                queue.append(neighbor)
                
    has_cycles = False
    
    # 3. Check for cycles
    if len(ordered_skills_names) != len(in_degree):
        has_cycles = True
        # If there's a cycle, we need to gracefully recover.
        # We will simply append the remaining skills that couldn't be sorted.
        # In a production app, you might want to use DFS to find and sever the exact back-edge.
        for node, deg in in_degree.items():
            if deg > 0 and node not in ordered_skills_names:
                ordered_skills_names.append(node)
                
    # 4. Map names back to full SkillNode objects
    ordered_skills = [skill_map[name] for name in ordered_skills_names]
    
    return StudyRoadmapResponse(
        document_id=document_id,
        ordered_skills=ordered_skills,
        has_cycles=has_cycles,
        adjacency_list=dict(graph)
    )
